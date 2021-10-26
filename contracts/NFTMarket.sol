// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
	using Counters for Counters.Counter;
	Counters.Counter private _itemIds;
	Counters.Counter private _itemsSold;

	address payable owner;
	uint256 listingPrice = 0.025 ether;

	constructor() {
		owner = payable(msg.sender);
	}

	struct MarketItem {
		uint itemId;
		address nftContract;
		uint256 tokenId;
		address payable seller;
		address payable owner;
		uint256 price;
		bool isSold;
	}

	mapping (uint256 => MarketItem) idToMarketItem;

	event MarketItemCreated(
		uint itemId,
		address nftContract,
		uint256 tokenId,
		address seller,
		address owner,
		uint256 price,
		bool isSold
	);

	event MarketItemSold(
		uint itemId,
		address nftContract,
		uint256 tokenId,
		address seller,
		address owner,
		uint256 price,
		bool isSold
	);

	function getListingPrice() public view returns (uint256) {
		return listingPrice;
	}

	function createMarketItem (address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {

		require (price > 0, "Price must be greater than 0!");
		require (msg.value == listingPrice, "Price must be equal to listing price!");
		
		_itemIds.increment();

		uint newItemId = _itemIds.current();

		idToMarketItem[newItemId] = MarketItem(
			newItemId,
			nftContract,
			tokenId,
			payable(msg.sender),
			payable(address(0)),
			price,
			false
		);

		IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
		emit MarketItemCreated(newItemId, nftContract, tokenId, msg.sender, address(0), price, false);
	}

	function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant {
		uint256 price = idToMarketItem[itemId].price;
		uint256 tokenId = idToMarketItem[itemId].tokenId;

		require(msg.value == price , "Please submit the required price in order to complete the purchase.");

		idToMarketItem[itemId].seller.transfer(msg.value);
		IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
		idToMarketItem[itemId].owner = payable(msg.sender);
		idToMarketItem[itemId].isSold = true;

		_itemsSold.increment();
		payable(owner).transfer(listingPrice);
	} 

	function fetchMarketItems() public view returns (MarketItem[] memory) {
		uint itemCount = _itemIds.current();
		uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
		uint counter = 0;

		MarketItem[] memory items = new MarketItem[](unsoldItemCount);

		for(uint256 i = 0; i < itemCount; i++) {
			if(idToMarketItem[i + 1].owner == address(0)) { // checking for next index because id is starting from 1
				uint256 currentId = idToMarketItem[i + 1].itemId;
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[counter] = currentItem;
				counter = counter+1;
			}
		}

		return items;
	}
	
	function fetchMyNFTs() public view returns (MarketItem[] memory) {
		uint itemCount = _itemIds.current();
		uint currentIndex = 0;
		uint totalNfts = 0;

		for(uint256 i = 0; i < itemCount; i++) {
			if(idToMarketItem[i + 1].owner == msg.sender) {
				totalNfts +=  1;
			}
		}

		MarketItem[] memory items = new MarketItem[](totalNfts);

		for(uint256 i = 0; i < totalNfts; i++) {
			if(idToMarketItem[i + 1].owner == msg.sender) {
				uint256 currentItemId = idToMarketItem[i + 1].itemId;
				MarketItem storage currentItem = idToMarketItem[currentItemId];
				items[currentIndex] = currentItem;
				currentIndex += 1;
			}
		}

		return items;
	}

	function fetchItemsCreated() public view returns (MarketItem[] memory) {
		uint itemCount = _itemIds.current();
		uint currentIndex = 0;
		uint totalCreated = 0;

		for(uint256 i = 0; i < itemCount; i++) {
			if(idToMarketItem[i + 1].seller == msg.sender){
				totalCreated += 1;
			}
		}

		MarketItem[] memory items = new MarketItem[](totalCreated);

		for(uint256 i = 0; i < itemCount; i++) {
			if(idToMarketItem[i + 1].seller == msg.sender) {
				uint256 currentId = idToMarketItem[i + 1].itemId;
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex += 1;
			}
		}

		return items;
	}
	
}
