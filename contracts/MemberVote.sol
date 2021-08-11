// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * membersVote contract:
 * 1. Secure funds from investment club members (ether)
 * 2. Track member contributions with shares
 * 3. Allow members to transfer shares
 * 4. Allow investment proposals to be created and voted
 * 5. Approve successful investment proposals (i.e send money)
 */

contract MembersVote {
    struct Proposal {
        uint256 id;
        string name;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        uint256 end;
        bool approved;
    }
    mapping(address => bool) public members;
    mapping(address => uint256) public shares;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(uint256 => Proposal) public proposals;
    uint256 public totalShares;
    uint256 public availableFunds;
    uint256 public contributionEnd;
    uint256 public nextProposalId;
    uint256 public voteTime;
    uint256 public quorum;
    address public owner;

    constructor(
        uint256 contributionTime,
        uint256 _voteTime,
        uint256 _quorum
    ) {
        require(_quorum > 1, "quorum must be more than 1 member");
        contributionEnd = block.timestamp + contributionTime;
        voteTime = _voteTime;
        quorum = _quorum;
        owner = msg.sender;
    }

    function contribute() external payable {
        require(
            block.timestamp < contributionEnd,
            "cannot contribute after contributionEnd"
        );
        members[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }

    function redeemShare(uint256 amount) external {
        require(shares[msg.sender] >= amount, "not enough shares");
        require(availableFunds >= amount, "not enough available funds");
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferShare(uint256 amount, address payable to) external {
        require(shares[msg.sender] >= amount, "not enough shares");
        shares[msg.sender] -= amount;
        shares[to] += amount;
        members[to] = true;
    }

    function createProposal(
        string calldata name,
        uint256 amount,
        address payable recipient
    ) external onlyMembers {
        require(availableFunds >= amount, "amount too big");
        proposals[nextProposalId] = Proposal(
            nextProposalId,
            name,
            amount,
            recipient,
            0,
            block.timestamp + voteTime,
            false
        );
        nextProposalId++;
    }

    function vote(uint256 proposalId) external onlyMembers {
        Proposal storage proposal = proposals[proposalId];
        require(
            votes[msg.sender][proposalId] == false,
            "members can only vote once for a proposal"
        );
        require(
            block.timestamp < proposal.end,
            "can only vote until proposal end date"
        );
        votes[msg.sender][proposalId] = true;
        proposal.votes += shares[msg.sender];
    }

    function approveProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp >= proposal.end,
            "cannot approve proposal before end date"
        );
        require(
            proposal.approved == false,
            "current proposal already approved"
        );
        require(
            ((proposal.votes * 100) / totalShares) >= quorum,
            "cannot approve proposal with votes # below quorum"
        );
        proposal.approved = true;
        _transferEther(proposal.amount, proposal.recipient);
    }

    function withdrawEther(uint256 amount, address payable to)
        external
        onlyOwner
    {
        _transferEther(amount, to);
    }

    function _transferEther(uint256 amount, address payable to) internal {
        require(amount <= availableFunds, "not enough availableFunds");
        availableFunds -= amount;
        to.transfer(amount);
    }

    //For ether returns of proposal investments
    receive() external payable {
        availableFunds += msg.value;
    }

    modifier onlyMembers() {
        require(members[msg.sender] == true, "only members");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}
