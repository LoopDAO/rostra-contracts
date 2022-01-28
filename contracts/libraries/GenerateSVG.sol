// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./NFTSVG.sol";
import "./SafeMath.sol";
import "./HexStrings.sol";
import "./Address.sol";

import "../interface/IERC20Metadata.sol";

library GenerateSVG {
    using SafeMathUpgradeable for uint256;
    using Strings for uint256;
    using SafeMath for uint160;
    using SafeMath for uint8;
    using HexStrings for uint256;
    using HexStrings for uint160;

    struct ConstructNFTParams {
        string name;
        uint256 tokenId;
        string creator;
        string owner;
        string creatorName;
        string ownerName;
        string title;
        string description;
        uint256 price;
        uint256 limit;
        string symbol;
        string baseTokenURI;
        string paperURL;
    }

    function generateSVGImage(ConstructNFTParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            creatorAddr: params.creator,
            ownerAddr: params.owner,
            creatorName: params.creatorName,
            ownerName: params.ownerName,
            title: params.title,
            description: params.description,
            price: params.price,
            limit: params.limit,
            name: params.name,
            symbol: params.symbol,
            baseTokenURI: params.baseTokenURI,
            paperURL: params.paperURL,
            tokenId: params.tokenId,
            color0: tokenToColorHex(uint160(Address.parseAddr(params.creator)), 136),
            color1: tokenToColorHex(uint160(Address.parseAddr(params.owner)), 136),
            color2: tokenToColorHex(uint160(Address.parseAddr(params.creator)), 0),
            color3: tokenToColorHex(uint160(Address.parseAddr(params.owner)), 0),
            x1: scale(
                getCircleCoord(
                    uint160(Address.parseAddr(params.creator)),
                    16,
                    params.tokenId
                ),
                0,
                255,
                16,
                274
            ),
            y1: scale(
                getCircleCoord(
                    uint160(Address.parseAddr(params.owner)),
                    16,
                    params.tokenId
                ),
                0,
                255,
                100,
                484
            ),
            x2: scale(
                getCircleCoord(
                    uint160(Address.parseAddr(params.creator)),
                    32,
                    params.tokenId
                ),
                0,
                255,
                16,
                274
            ),
            y2: scale(
                getCircleCoord(
                    uint160(Address.parseAddr(params.owner)),
                    32,
                    params.tokenId
                ),
                0,
                255,
                100,
                484
            ),
            x3: scale(
                getCircleCoord(
                    uint160(Address.parseAddr(params.creator)),
                    48,
                    params.tokenId
                ),
                0,
                255,
                16,
                274
            ),
            y3: scale(
                getCircleCoord(
                    uint160(Address.parseAddr(params.owner)),
                    48,
                    params.tokenId
                ),
                0,
                255,
                100,
                484
            )
        });

        return NFTSVG.generateSVG(svgParams);
    }

    // function generateSVGImageBase64(
    //     address _newPaper,
    //     address _creator,
    //     string memory _creatorName,
    //     string memory _title,
    //     string memory _description,
    //     uint256 _price,
    //     uint256 _limit,
    //     string memory _name,
    //     string memory _symbol,
    //     string memory _baseTokenURI,
    //     string memory _paperURL
    // ) internal view returns (string memory svg) {

    //     string memory svg = generateSVGImage(ConstructNFTParams({
    //         tokenId: 0,
    //         creator: _newPaper,
    //         owner: _creator,
    //         quoteTokenSymbol: _name,
    //         baseTokenSymbol: _symbol,
    //         quoteTokenDecimals: 18,
    //         baseTokenDecimals: 18,
    //         flipRatio: false,
    //         tickLower: 0,
    //         tickUpper: 0,
    //         tickCurrent: 0,
    //         tickSpacing: 0,
    //         fee: 0,
    //         poolAddress: _creator
    //     }));
    //     string memory image = Base64.encode(
    //         bytes(
    //             svg
    //         )
    //     );
    // }
    function tokenToColorHex(uint256 token, uint256 offset)
        internal
        pure
        returns (string memory str)
    {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function getCircleCoord(
        uint256 tokenAddress,
        uint256 offset,
        uint256 tokenId
    ) internal pure returns (uint256) {
        return (sliceTokenHex(tokenAddress, offset) * tokenId) % 255;
    }

    function sliceTokenHex(uint256 token, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        return uint256(uint8(token >> offset));
    }

    function scale(
        uint256 n,
        uint256 inMn,
        uint256 inMx,
        uint256 outMn,
        uint256 outMx
    ) internal pure returns (string memory) {
        return
            (n.sub(inMn).mul(outMx.sub(outMn)).div(inMx.sub(inMn)).add(outMn))
                .toString();
    }



    function feeToPercentString(uint24 fee)
        internal
        pure
        returns (string memory)
    {
        return "123343";
    }

    function overRange(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent
    ) internal pure returns (int8) {
        if (tickCurrent < tickLower) {
            return -1;
        } else if (tickCurrent > tickUpper) {
            return 1;
        } else {
            return 0;
        }
    }
}
