// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MovieFanSBT is ERC721, Ownable {
    uint256 private _nextTokenId;

    mapping(address => uint256) public addressToTokenId;

    mapping(uint256 => FanProfile) public tokenToProfile;

    struct FanProfile {
        address fanAddress;
        uint256 reputation;
        uint256 jointAt;
        uint256 totalRatings;
    }

    event SBTMinted(address indexed fanAddress, uint256 indexed tokenId);
    event ReputationUpdated(address indexed fanAddress, uint256 newReputation);

    constructor(
        address initialOwner
    ) ERC721("MovieFanSBT", "MFSBT") Ownable(initialOwner) {}

    function mintSBT(address fanAddress) external onlyOwner {
        require(
            balanceOf(fanAddress) == 0,
            "SBT already minted for this address"
        );

        _nextTokenId++;
        uint256 tokenId = _nextTokenId;

        _safeMint(fanAddress, tokenId);
        addressToTokenId[fanAddress] = tokenId;

        tokenToProfile[tokenId] = FanProfile({
            fanAddress: fanAddress,
            reputation: 0,
            jointAt: block.timestamp,
            totalRatings: 0
        });

        emit SBTMinted(fanAddress, tokenId);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        if (to != address(0) && auth != address(0)) {
            revert("This is a Soulbound Token and cannot be transferred");
        }
        return super._update(to, tokenId, auth);
    }

    function updateReputation(
        address fan,
        uint256 newReputation
    ) external onlyOwner {
        uint256 tokenId = addressToTokenId[fan];
        require(tokenId != 0, "Fan does not have SBT");

        FanProfile storage profile = tokenToProfile[tokenId];
        profile.reputation = newReputation;
        profile.totalRatings += 1;

        emit ReputationUpdated(fan, newReputation);
    }

    // 获取用户信誉分
    function getReputation(address fan) external view returns (uint256) {
        uint256 tokenId = addressToTokenId[fan];
        if (tokenId == 0) return 0;
        return tokenToProfile[tokenId].reputation;
    }

    // 获取用户资料
    function getProfile(address fan) external view returns (FanProfile memory) {
        uint256 tokenId = addressToTokenId[fan];
        require(tokenId != 0, "Fan does not have SBT");
        return tokenToProfile[tokenId];
    }

    function isMovieFan(address fan) external view returns (bool) {
        return balanceOf(fan) > 0;
    }
}
