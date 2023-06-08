// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    //string public ipfsHash;

    uint public highestBid;
    address public highestBidder;
    address[] public participants;

    mapping(address => uint) public bids;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 5;
        //ipfsHash = _ipfsHash;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.number < endBlock, "Auction has already ended.");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.number >= endBlock, "Auction has not yet ended.");
        _;
    }

    function balance() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    
    function bid() public payable onlyBeforeEnd {
        require(auctionState == State.Running, "Auction Time out");
        require(msg.value > highestBid, "There is already a higher bid.");
        require(msg.sender != owner, "The owner cannot bid on their own auction.");

        if (highestBid != 0) {
            bids[highestBidder] += highestBid;
            participants.push(msg.sender);
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit HighestBidIncreased(highestBidder, highestBid);
    }

    function withdraw() public {
        uint amount = bids[msg.sender];

        if (amount > 0) {
            bids[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
        payable(owner).transfer(highestBid);
    }

    function endAuction() public payable onlyOwner onlyAfterEnd {

        require(auctionState == State.Running, "The auction has already ended.");

        auctionState = State.Ended;

        emit AuctionEnded(highestBidder, highestBid);
        payable(owner).transfer(highestBid);
    }

}