// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

import '../libraries/NFTSVG.sol';
import '../libraries/HexStrings.sol';
import '../libraries/GenerateSVG.sol';
import '../libraries/Address.sol';

contract NFTSvgTest {
  using HexStrings for uint256;

  function feeToPercentString(uint24 fee) public pure returns (string memory) {
    return GenerateSVG.feeToPercentString(fee);
  }

  function addressToString(address _address) public pure returns (string memory) {
    return Address.addressToString(_address);
  }

  function generateSVGImage(GenerateSVG.ConstructNFTParams memory params) public pure returns (string memory) {
    return GenerateSVG.generateSVGImage(params);
  }

  function generateSVGImage2(
    string memory _creatorName,
    string memory _title,
    string memory _description,
    uint256 _price,
    uint256 _limit,
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    string memory _paperURL
  ) public returns (string memory) {
    return
      GenerateSVG.generateSVGImage(
        GenerateSVG.ConstructNFTParams({
          tokenId: 1230,
          creator: Address.addressToString(msg.sender),
          owner: Address.addressToString(msg.sender),
          creatorName: _creatorName,
          ownerName: _creatorName,
          title: _name,
          name: _name,
          description: _description,
          price: _price,
          limit: _limit,
          symbol: _symbol,
          baseTokenURI: _baseTokenURI,
          paperURL: _paperURL
        })
      );
  }

  function tokenToColorHex(address token, uint256 offset) public pure returns (string memory) {
    return GenerateSVG.tokenToColorHex(uint160(token), offset);
  }

  function sliceTokenHex(address token, uint256 offset) public pure returns (uint256) {
    return GenerateSVG.sliceTokenHex(uint160(token), offset);
  }

  function isRare(uint256 tokenId, address poolAddress) public pure returns (bool) {
    return NFTSVG.isRare(tokenId, poolAddress);
  }

  event EventGenSVG(
    address contractAddress,
    address creatorAddress,
    string creatorName,
    string title,
    string description,
    uint256 price,
    uint256 limit,
    string name,
    string symbol,
    string baseTokenURI,
    string svg
  );
}
