// SPDX-License-Identifier: MIT
import "./Token/CRGToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

pragma solidity 0.8.10;

contract DAO {
    string name;
    string symbol;
    address tokenAddress;

    uint256 proposalID;
    uint256 minQuorum;

    mapping(uint256 => Proposal) proposals;

    struct Proposal {
        uint256 amount;
        uint256 proposalID;
        uint256 votingDeadline;
        address recipient;
        address creator;
        string description;
        bytes proposalHash;
        bool open;
        uint256 sum;
        mapping(address => uint256) voters;
    }

    // _minQuorum < 100%
    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenAddress,
        uint256 _minQuorum
    ) isValidMinQuorum(_minQuorum) {
        name = _name;
        symbol = _symbol;
        tokenAddress = _tokenAddress;
        minQuorum = _minQuorum / 100;
    }

    modifier isValidMinQuorum(uint256 _minQuorum) {
        require(
            _minQuorum <= 49 && _minQuorum >= 15,
            "DAO: Minimum Quorum can't be more than 49% and less then 15%"
        );
        _;
    }

    modifier onlyTokenHolders() {
        require(
            CRGToken(tokenAddress).balanceOf(msg.sender) > 0,
            "DAO: You are not a token owner"
        );
        _;
    }

    modifier shouldHasEnoughBalance() {
        require(
            CRGToken(tokenAddress).balanceOf(msg.sender) > msg.value,
            "DAO: You don't have enough balance to make the transaction"
        );
        _;
    }

    modifier checkTransactionAmount() {
        require(
            msg.value != 0,
            "You have to specify the amount you want to donate"
        );
        _;
    }

    modifier proposalExist(uint256 _proposalID) {
        require(
            proposals[_proposalID].creator != address(0),
            "DAO: Proposal doesn't exist"
        );
        _;
    }

    function newProposal(
        address _recipient,
        string memory _description,
        bytes memory _byteCode,
        uint64 _votingDeadline
    ) external payable onlyTokenHolders returns (uint256 _proposalID) {
        Proposal storage proposal = proposals[proposalID++];

        proposal.creator = msg.sender;
        proposal.recipient = _recipient;
        proposal.description = _description;
        proposal.proposalHash = _byteCode;
        proposal.votingDeadline = _votingDeadline;

        return proposalID;
    }

    function vote(uint256 _proposalID)
        external
        payable
        onlyTokenHolders
        shouldHasEnoughBalance
    {
        Proposal storage proposal = proposals[_proposalID];

        proposal.voters[msg.sender] = msg.value;
        proposal.sum += msg.value;

        emit Voted(_proposalID, msg.sender);
    }

    function isProposalApproved(uint256 _proposalID)
        internal
        view
        returns (bool)
    {
        uint256 totalSupply = CRGToken(tokenAddress).totalSupply();

        return proposals[_proposalID].sum >= totalSupply * minQuorum;
    }

    function isEnoughQuorum(uint256 _proposalID) internal {
        // if (proposals[_proposalID].vote.sumYes >= )
    }

    function minimumQuorum() internal {
        // return CRGToken(tokenAddress).totalSupply() * getPercentByQuorum(minimumQuorum)
    }

    function executeProposal(uint256 _proposalID, bytes memory _byteCode)
        external
        proposalExist(_proposalID)
        returns (bool _success)
    {
        Proposal storage proposal = proposals[_proposalID];

        if (proposal.open && block.timestamp > proposal.votingDeadline) {
            closeProposal(_proposalID);
            return true;
        }

        // require(proposal.open && block.timestamp > proposal.votingDeadline);

        (bool success, ) = proposal.recipient.call(proposal.proposalHash);

        require(success, "DAO: The called function is not in the contract");

        emit ProposalExecutionSucceeded(
            proposal.proposalID,
            proposal.description,
            proposal.recipient
        );
        closeProposal(_proposalID);
        return true;
    }

    function closeProposal(uint256 _proposalID) internal {
        proposals[_proposalID].open = false;
    }

    function unVote() external {}

    function getBalance() external view returns (uint256) {
        return CRGToken(tokenAddress).balanceOf(msg.sender);
    }

    // function getProposalDescrip(uint256 _proposalID) external view returns (Proposal memory) {
    //     return proposals[_proposalID];
    // }

    event ProposalCreated(address indexed _msgSender, bytes _byteCode);
    event Voted(uint256 _proposalID, address indexed voter);
    event ProposalExecutionSucceeded(
        uint256 _proposalID,
        string _description,
        address indexed _recipient
    );
}
