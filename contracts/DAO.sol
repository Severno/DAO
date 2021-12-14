// SPDX-License-Identifier: MIT
import "./Token/CRGToken.sol";

pragma solidity 0.8.10;

contract DAO {
    uint256 proposalId;
    uint256 minQuorum;

    CRGToken private token;

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

    /** @notice Creates DAO contract.
     * @param _tokenAddress The address of the token that wiil be used for voting.
     * @param _minQuorum Minimum quorum for successful voting.
     */
    constructor(address _tokenAddress, uint256 _minQuorum)
        isValidMinQuorum(_minQuorum)
    {
        token = CRGToken(_tokenAddress);
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
            token.balanceOf(msg.sender) > 0,
            "DAO: You are not a token owner"
        );
        _;
    }

    modifier shouldHasEnoughBalance() {
        require(
            token.balanceOf(msg.sender) > msg.value,
            "DAO: You don't have enough balance to make the transaction"
        );
        _;
    }

    modifier checkTransactionAmount() {
        require(
            msg.value != 0,
            "DAO: You have to specify the amount you want to donate"
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

    modifier proposalIsOpened(uint256 _proposalId) {
        require(
            proposals[_proposalId].open,
            "DAO: You're trying to call proposal that's already closed"
        );
        _;
    }

    modifier proposalHasEnoughQuorum(uint256 _proposalId) {
        require(
            _isProposalHasEnoughQuorum(_proposalId),
            "DAO: You're trying to call proposal who has insufficient quorum"
        );
        _;
    }

    modifier proposalIsOutdated(uint256 _proposalId) {
        require(
            !_isProposalDeadlinePassed(_proposalId),
            "DAO: You're trying to call proposal that's is outdated"
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

    /** @notice Create new proposal.
     * @param _recipient The address of the contract to be be called.
     * @param _description Proposal description.
     * @param _byteCode ByteCode to execute if proposal will pass.
     * @param _votingDeadline How many days of voting will last.
     * @return _proposalId New proposal ID.
     */
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

    /** @notice Get proposal information.
     * @param _proposalId Id of the calling proposal.
     * @return _description Proposal description.
     * @return _open Voting status, true if still voting, false if voting ends.
     * @return _sum Sum of voting tokens.
     */
    function getProposal(uint256 _proposalId)
        external
        view
        proposalExist(_proposalId)
        returns (
            string memory _description,
            bool _open,
            uint256 _sum
        )
    {
        return (
            proposals[_proposalId].description,
            proposals[_proposalId].open,
            proposals[_proposalId].sum
        );
    }

    function vote(uint256 _proposalId)
        external
        payable
        onlyTokenHolders
        shouldHasEnoughBalance
        proposalExist(_proposalId)
        proposalIsOpened(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];

        uint256 amount = msg.value;

        token.transferFrom(msg.sender, address(this), msg.value);

        proposal.voters[msg.sender] = amount;
        proposal.sum += amount;

        emit Voted(_proposalId, msg.sender, amount);
    }

    function unVote(uint256 _proposalId) external shouldBeAVoter(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        uint256 voterAmount = proposal.voters[msg.sender];

        token.transfer(msg.sender, voterAmount);

        proposal.sum -= voterAmount;
        proposal.voters[msg.sender] = 0;

        emit UnVoted(_proposalId, msg.sender, voterAmount);
    }

    function executeProposal(uint256 _proposalId)
        external
        proposalExist(_proposalId)
        proposalIsOpened(_proposalId)
        proposalHasEnoughQuorum(_proposalId)
        returns (bool _success)
    {
        if (_closeOutdatedProposal(_proposalId)) return true;
        if (_closeSuccessfulProposal(_proposalId)) return true;

        return false;
    }

    function _closeProposal(uint256 _proposalId, bool _result) internal {
        proposals[_proposalId].open = false;

        emit ProposalClosed(
            _proposalId,
            proposals[_proposalId].description,
            _result
        );
    }

    function _closeSuccessfulProposal(uint256 _proposalId)
        internal
        returns (bool success)
    {
        if (
            !_isProposalDeadlinePassed(_proposalId) &&
            _isProposalHasEnoughQuorum(_proposalId)
        ) {
            _executeProposal(_proposalId);
            _closeProposal(_proposalId, true);

            return true;
        }
        return false;
    }

    function _closeOutdatedProposal(uint256 _proposalId)
        internal
        returns (bool success)
    {
        if (
            _isProposalDeadlinePassed(_proposalId) &&
            !_isProposalHasEnoughQuorum(_proposalId)
        ) {
            _closeProposal(_proposalId, false);

            return true;
        }
        return false;
    }

    function _isProposalHasEnoughQuorum(uint256 _proposalId)
        internal
        view
        returns (bool)
    {
        uint256 totalSupply = token.totalSupply();

        return
            proposals[_proposalId].sum >= (((totalSupply / 100) * minQuorum));
    }

    function _isProposalDeadlinePassed(uint256 _proposalId)
        internal
        view
        returns (bool)
    {
        return block.timestamp > proposals[_proposalId].votingDeadline;
    }

    function _executeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        (bool success, ) = proposal.recipient.call(proposal.proposalHash);

        require(success, "DAO: The called function is not in the contract");

        emit ProposalExecutionSucceeded(
            proposal.proposalId,
            proposal.description,
            proposal.recipient
        );
    }

    event ProposalCreated(
        address indexed _recipient,
        address indexed _creator,
        bytes _byteCode,
        uint256 _proposalId
    );
    event ProposalExecutionSucceeded(
        uint256 _proposalId,
        string _description,
        address indexed _recipient
    );
    event Voted(uint256 _proposalId, address indexed _voter, uint256 _amount);
    event UnVoted(uint256 _proposalId, address indexed _voter, uint256 _amount);
    event ProposalClosed(
        uint256 _proposalId,
        string _description,
        bool _result
    );
}
