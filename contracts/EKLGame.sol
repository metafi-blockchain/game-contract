// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EKLGame is Ownable, Pausable, ReentrancyGuard {
  struct UserActive {
    address user;
    uint256 time;
  }

  struct Fee {
    IERC20 currency;
    uint256 amount;
  }

  struct NFT {
    mapping(uint256 => UserActive) idToNfts;
    uint256 duration;
    Fee[] fees; // 0: active 1: deactive
    bool valid;
  }

  mapping(address => NFT) nfts;

  address public vault;

  event Active(
    address nftAddress,
    uint256 nftId,
    address user,
    address feeContract,
    uint256 feeAmount,
    uint256 time
  );
  event Deactive(address nftAddress, uint256 nftId, address user, uint256 time);

  constructor(address _vault) Ownable(_msgSender()) {
    require(_vault != address(0), "Error: Vault invalid");

    vault = _vault;
  }

  event SetNFT(
    address nftAddress,
    uint256 duration,
    IERC20[] currencies,
    uint256[] amounts,
    bool valid
  );

  function setNFT(
    address _nftAddress,
    uint256 _duration,
    IERC20[] memory _currencies,
    uint256[] memory _amounts,
    bool _valid
  ) external onlyOwner {
    require(address(_nftAddress) != address(0), "Error: NFT address(0)");
    require(_currencies.length == 2, "Error: currencies invalid");
    require(_currencies.length == _amounts.length, "Error: currencies invalid");

    nfts[_nftAddress].duration = _duration;
    for (uint8 i = 0; i < _currencies.length; i++) {
      nfts[_nftAddress].fees.push(Fee(_currencies[i], _amounts[i]));
    }
    nfts[_nftAddress].valid = _valid;

    emit SetNFT(_nftAddress, _duration, _currencies, _amounts, _valid);
  }

  function getNFTInfo(
    address _nftAddress
  ) external view returns (uint256, address[] memory, uint256[] memory, bool) {
    uint256 feeLength = nfts[_nftAddress].fees.length;
    address[] memory currencies = new address[](feeLength);
    uint256[] memory amounts = new uint256[](feeLength);

    for (uint256 i = 0; i < feeLength; i++) {
      currencies[i] = address(nfts[_nftAddress].fees[i].currency);
      amounts[i] = nfts[_nftAddress].fees[i].amount;
    }

    return (
      nfts[_nftAddress].duration,
      currencies,
      amounts,
      nfts[_nftAddress].valid
    );
  }

  function setVault(address _vault) external onlyOwner {
    require(_vault != address(0), "Error: Vault address(0)");
    vault = _vault;
  }

  function active(
    address _nftAddress,
    uint256 _nftId
  ) external payable whenNotPaused nonReentrant {
    require(nfts[_nftAddress].valid, "Error: NFT contract invalid");
    require(
      IERC721(_nftAddress).ownerOf(_nftId) == _msgSender(),
      "Error: you are not the owner"
    );

    //transfer NFT for market contract
    IERC721(_nftAddress).transferFrom(_msgSender(), address(this), _nftId);
    nfts[_nftAddress].idToNfts[_nftId].user = _msgSender();
    nfts[_nftAddress].idToNfts[_nftId].time = block.timestamp;

    //charge fee
    Fee memory fee = nfts[_nftAddress].fees[0];
    if (fee.amount > 0) {
      if (address(fee.currency) == address(0)) {
        payable(vault).transfer(fee.amount);
        //transfer BNB back to user if amount > fee
        if (msg.value > fee.amount) {
          payable(_msgSender()).transfer(msg.value - fee.amount);
        }
      } else {
        fee.currency.transferFrom(_msgSender(), vault, fee.amount);
        //transfer BNB back to user if currency is not address(0)
        if (msg.value != 0) {
          payable(_msgSender()).transfer(msg.value);
        }
      }
    }

    emit Active(
      _nftAddress,
      _nftId,
      _msgSender(),
      address(fee.currency),
      fee.amount,
      block.timestamp
    );
  }

  function deactive(
    address _nftAddress,
    uint256 _nftId
  ) external payable whenNotPaused nonReentrant {
    require(nfts[_nftAddress].valid, "Error: NFT contract invalid");

    require(
      nfts[_nftAddress].idToNfts[_nftId].user == _msgSender(),
      "Error: you are not the owner"
    );

    //check active duration
    require(
      block.timestamp - nfts[_nftAddress].idToNfts[_nftId].time >=
        nfts[_nftAddress].duration,
      "Error: wait to deactive"
    );

    IERC721(_nftAddress).transferFrom(address(this), _msgSender(), _nftId);

    delete nfts[_nftAddress].idToNfts[_nftId];

    //charge fee
    Fee memory fee = nfts[_nftAddress].fees[1];
    if (fee.amount > 0) {
      if (address(fee.currency) == address(0)) {
        payable(vault).transfer(fee.amount);
        //transfer BNB back to user if amount > fee
        if (msg.value > fee.amount) {
          payable(_msgSender()).transfer(msg.value - fee.amount);
        }
      } else {
        fee.currency.transferFrom(_msgSender(), vault, fee.amount);
        //transfer BNB back to user if currency is not address(0)
        if (msg.value != 0) {
          payable(_msgSender()).transfer(msg.value);
        }
      }
    }

    emit Deactive(_nftAddress, _nftId, _msgSender(), block.timestamp);
  }
}
