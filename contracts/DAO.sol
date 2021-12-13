// SPDX-License-Identifier: MIT
import "./Token/CRGToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

pragma solidity 0.8.10;

interface DAOInterface {
    function newProposal(
        address _recipient,
        string memory _description,
        bytes memory _byteCode,
        uint64 _votingDeadline
    ) external payable returns (uint256 _proposalId);
}

contract DAO {
    string name;
    string symbol;
    address tokenAddress;

    uint256 proposalId;
    uint256 minQuorum;

    mapping(address => uint256) private _balances;

    mapping(uint256 => Proposal) proposals;

    struct Proposal {
        uint256 amount;
        uint256 proposalId;
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
        minQuorum = _minQuorum;
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

    modifier proposalExist(uint256 _proposalId) {
        require(
            proposals[_proposalId].creator != address(0),
            "DAO: Proposal doesn't exist"
        );
        _;
    }

    modifier shouldBeAVoter(uint256 _proposalId) {
        require(
            proposals[_proposalId].voters[msg.sender] != 0,
            "DAO: You're not a voter"
        );
        _;
    }

    function newProposal(
        address _recipient,
        string memory _description,
        bytes memory _byteCode,
        uint64 _votingDeadline
    ) external payable onlyTokenHolders returns (uint256 _proposalId) {
        Proposal storage proposal = proposals[proposalId];

        proposal.creator = msg.sender;
        proposal.recipient = _recipient;
        proposal.description = _description;
        proposal.proposalHash = _byteCode;
        proposal.votingDeadline = _votingDeadline;
        proposal.open = true;

        emit ProposalCreated(_recipient, msg.sender, _byteCode, proposalId);
        proposalId++;

        return proposalId - 1;
    }

    function vote(uint256 _proposalId)
        external
        payable
        onlyTokenHolders
        shouldHasEnoughBalance
    {
        uint256 amount = msg.value;
        Proposal storage proposal = proposals[_proposalId];

        CRGToken(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            msg.value
        );

        proposal.voters[msg.sender] = amount;
        proposal.sum += amount;

        emit Voted(_proposalId, msg.sender, amount);
    }

    function executeProposal(uint256 _proposalId)
        external
        proposalExist(_proposalId)
        returns (bool _success)
    {
        Proposal storage proposal = proposals[_proposalId];

        require(
            proposal.open,
            "DAO: You're trying to call proposal that's already closed"
        );

        // require(
        //     _isProposalHasEnoughQuorum(_proposalId),
        //     "DAO: Proposal doesn't get enough votes to be executed"
        // );

        if (
            _isProposalDeadlinePassed(_proposalId) &&
            !_isProposalHasEnoughQuorum(_proposalId)
        ) {
            closeProposal(_proposalId);
            return true;
        }

        if (
            proposal.open &&
            _isProposalHasEnoughQuorum(_proposalId) &&
            !_isProposalDeadlinePassed(_proposalId)
        ) {
            (bool success, ) = proposal.recipient.call(proposal.proposalHash);

            require(success, "DAO: The called function is not in the contract");

            emit ProposalExecutionSucceeded(
                proposal.proposalId,
                proposal.description,
                proposal.recipient,
                proposal.sum,
                CRGToken(tokenAddress).totalSupply(),
                CRGToken(tokenAddress).totalSupply() * minQuorum
            );

            closeProposal(_proposalId);

            return true;
        }

        return false;
    }

    function closeProposal(uint256 _proposalId) internal {
        proposals[_proposalId].open = false;
    }

    function unVote(uint256 _proposalId) external shouldBeAVoter(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 voterAmount = proposal.voters[msg.sender];

        require(
            block.timestamp >= proposal.votingDeadline,
            "DAO: Can't unvote completed voting"
        );

        CRGToken(tokenAddress).transferFrom(
            address(this),
            msg.sender,
            voterAmount
        );

        proposal.sum -= voterAmount;
        proposal.voters[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return CRGToken(tokenAddress).balanceOf(address(this));
    }

    function approveSomething() public payable {
        CRGToken(tokenAddress).approve(address(this), 100);
        // CRGToken(tokenAddress).transfer(address(this), 100);
        address msgSender = CRGToken(tokenAddress).getMsgSender();
        uint256 balance = CRGToken(tokenAddress).balanceOf(address(this));
        uint256 balance1 = CRGToken(tokenAddress).balanceOf(msg.sender);
        uint256 allowance = CRGToken(tokenAddress).allowance(
            msg.sender,
            address(this)
        );
        uint256 allowance1 = CRGToken(tokenAddress).allowance(
            address(this),
            msg.sender
        );
        emit Allow(
            balance,
            balance1,
            allowance,
            allowance1,
            address(this),
            msg.sender,
            msgSender
        );
    }

    function _isProposalHasEnoughQuorum(uint256 _proposalId)
        internal
        view
        returns (bool)
    {
        uint256 totalSupply = CRGToken(tokenAddress).totalSupply();

        return proposals[_proposalId].sum >= ((totalSupply / 100) * minQuorum);
    }

    function _isProposalDeadlinePassed(uint256 _proposalId)
        internal
        view
        returns (bool)
    {
        return block.timestamp > proposals[_proposalId].votingDeadline;
    }

    event Allow(
        uint256 baalnce,
        uint256 balance1,
        uint256 amount,
        uint256 amount1,
        address _contract,
        address _msgSender,
        address _msgSenderErc
    );
    event ProposalCreated(
        address indexed _recipient,
        address indexed _creator,
        bytes _byteCode,
        uint256 _proposalId
    );
    event ProposalExecutionSucceeded(
        uint256 _proposalId,
        string _description,
        address indexed _recipient,
        uint256 sum,
        uint256 totalSupply,
        uint256 quorum
    );
    event Voted(uint256 _proposalId, address indexed _voter, uint256 _amount);
}
