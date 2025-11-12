#!/usr/bin/env node
/**
 * 自动将合约部署广播中的 ABI 和地址同步到前端代码
 * 用法: node export-abi.mjs [chainId]
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * 将地址转换为 EIP-55 校验和格式（使用 foundry cast）
 * @param {string} address - 以太坊地址
 * @returns {string} 校验和格式的地址
 */
function toChecksumAddress(address) {
  try {
    // 使用 foundry 的 cast 工具进行地址校验和转换
    const checksummed = execSync(`cast to-check-sum-address ${address}`, {
      encoding: 'utf-8',
    }).trim();
    return checksummed;
  } catch (error) {
    // 如果 cast 不可用，返回原地址
    console.warn(`   ⚠️  无法转换地址校验和: ${error.message}`);
    return address;
  }
}

// 配置
const CHAIN_ID = process.argv[2] || '31337';
const CONTRACT_ROOT = path.resolve(__dirname, '..');
const BROADCAST_DIR = path.join(CONTRACT_ROOT, 'broadcast', 'Deploy.s.sol', CHAIN_ID);
const RUN_FILE = path.join(BROADCAST_DIR, 'run-latest.json');
const FRONTEND_CONTRACTS_DIR = path.resolve(CONTRACT_ROOT, '..', 'dapp', 'src', 'app', 'contracts');

function toCamelCase(name) {
  // MovieRating -> movieRating
  return name.charAt(0).toLowerCase() + name.slice(1);
}

function toConstantCase(name) {
  // MovieRating -> MOVIE_RATING
  return name.replace(/([A-Z])/g, '_$1').replace(/^_/, '').toUpperCase();
}

async function main() {
  console.log(`🔧 同步合约 ABI 到前端 (Chain ID: ${CHAIN_ID})...`);

  // 检查 run-latest.json
  if (!fs.existsSync(RUN_FILE)) {
    console.error(`❌ 未找到部署广播文件: ${RUN_FILE}`);
    console.error('   请先运行 forge script 部署合约');
    process.exit(1);
  }

  // 读取广播数据
  const broadcastData = JSON.parse(fs.readFileSync(RUN_FILE, 'utf-8'));
  
  // 提取 CREATE 类型的合约
  const deployedContracts = broadcastData.transactions.filter(
    (tx) => tx.transactionType === 'CREATE'
  );

  if (deployedContracts.length === 0) {
    console.log('⚠️  未找到已部署的合约');
    return;
  }

  console.log(`📦 找到 ${deployedContracts.length} 个已部署合约`);

  // 确保前端目录存在
  if (!fs.existsSync(FRONTEND_CONTRACTS_DIR)) {
    fs.mkdirSync(FRONTEND_CONTRACTS_DIR, { recursive: true });
  }

  // 处理每个合约
  for (const contract of deployedContracts) {
    const { contractName, contractAddress } = contract;
    
    // 转换为校验和格式地址（EIP-55）
    const checksummedAddress = toChecksumAddress(contractAddress);
    
    console.log(`\n📝 处理合约: ${contractName}`);
    console.log(`   地址: ${checksummedAddress}`);

    try {
      // 方法1: 直接读取 out/ 目录的编译产物 (更可靠)
      const artifactPath = path.join(CONTRACT_ROOT, 'out', `${contractName}.sol`, `${contractName}.json`);
      
      let abi;
      if (fs.existsSync(artifactPath)) {
        const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf-8'));
        abi = artifact.abi;
        console.log(`   📂 从编译产物读取: ${path.basename(artifactPath)}`);
      } else {
        // 方法2: 降级使用 forge inspect (可能有终端输出干扰)
        console.log(`   ⚠️  编译产物未找到，尝试 forge inspect...`);
        const abiJson = execSync(`forge inspect ${contractName} abi 2>/dev/null`, {
          cwd: CONTRACT_ROOT,
          encoding: 'utf-8',
        }).trim();
        abi = JSON.parse(abiJson);
      }
      if (!Array.isArray(abi)) {
        throw new Error('ABI 格式无效');
      }

      // 生成 TypeScript 文件内容
      const timestamp = new Date().toISOString();
      const commitHash = broadcastData.commit || 'unknown';
      const constantPrefix = toConstantCase(contractName);
      const fileName = toCamelCase(contractName);

      const tsContent = `// Auto-generated from contract deployment
// Generated at: ${timestamp}
// Chain ID: ${CHAIN_ID}
// Commit: ${commitHash}
// DO NOT EDIT MANUALLY - changes will be overwritten

export const ${constantPrefix}_ADDRESS = '${checksummedAddress}' as const;

export const ${constantPrefix}_ABI = ${JSON.stringify(abi, null, 2)} as const;

export const ${constantPrefix}_CONTRACT = {
  address: ${constantPrefix}_ADDRESS,
  abi: ${constantPrefix}_ABI,
} as const;
`;

      // 写入文件
      const outputPath = path.join(FRONTEND_CONTRACTS_DIR, `${fileName}.ts`);
      fs.writeFileSync(outputPath, tsContent, 'utf-8');
      console.log(`   ✅ 已生成: ${path.relative(process.cwd(), outputPath)}`);

      // 可选：同时保存原始 ABI JSON
      const abiDir = path.join(FRONTEND_CONTRACTS_DIR, 'abi');
      if (!fs.existsSync(abiDir)) {
        fs.mkdirSync(abiDir, { recursive: true });
      }
      const abiPath = path.join(abiDir, `${contractName}.json`);
      fs.writeFileSync(abiPath, JSON.stringify(abi, null, 2), 'utf-8');
      console.log(`   📄 ABI JSON: ${path.relative(process.cwd(), abiPath)}`);

    } catch (error) {
      console.error(`   ❌ 处理失败: ${error.message}`);
      process.exit(1);
    }
  }

  console.log('\n✨ 同步完成！');
  console.log(`\n💡 提示: 如需支持多链,可在前端创建 addresses.json 或使用环境变量切换地址`);
}

main().catch((error) => {
  console.error('💥 脚本执行失败:', error);
  process.exit(1);
});
