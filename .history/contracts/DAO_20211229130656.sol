// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IDAO.sol";

/** @title DAO contract.  */
contract DAO is IDAO {
    uint256 proposalId;
    uint256 public minQuorum;
    uint256 public votingPeriod = 3 days;

    using SafeERC20 for IERC20;

    IERC20 private token;

    address daoOwner;

    mapping(address => uint256) public withdrawLock; // address => timestamp
    mapping(address => uint256) private balances;
    mapping(address => mapping(uint256 => address[])) private delegates; // address of delegate, _proposalId, users who deletated
    mapping(uint256 => mapping(address => Vote)) private delegatedVoting; // _proposalId, adress user who deletated, Vote struct
    mapping(uint256 => Proposal) public proposals;

    struct Vote {
        uint256 delegated;
        address from;
        bool isVoted;
    }

    struct Proposal {
        uint256 sum;
        uint256 proposalId;
        uint256 votingDeadline;
        address recipient;
        address creator;
        string description;
        bytes proposalHash;
        bool open;
        mapping(address => uint256) voters;
    }

    /** @dev Creates DAO contract.
     * @param _tokenAddress The address of the token that wiil be used for voting.
     * @param _minQuorum Minimum quorum for successful voting.
     */
    constructor(address _tokenAddress, uint256 _minQuorum) {
        require(
            _minQuorum <= 49 && _minQuorum >= 15,
            "DAO: Minimum Quorum can't be more than 49% and less then 15%"
        );
        token = IERC20(_tokenAddress);
        minQuorum = _minQuorum;
        daoOwner = msg.sender;
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

    modifier proposalInProgress(uint256 _proposalId) {
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

    /** @dev Deposit tokens to DAO.
     * @param _amount Amount deposited tokens.
     */
    function deposit(uint256 _amount) external payable {
        token.safeTransferFrom(msg.sender, address(this), _amount);

        balances[msg.sender] += _amount;

        emit Deposit(msg.sender, _amount);
    }

    /** @dev Withdraw tokens from DAO to user.
     * @param _amount Amount withdraw tokens.
     */
    function withdraw(uint256 _amount) external payable {
        require(
            withdrawLock[msg.sender] < block.timestamp,
            "DAO: Can't withdraw before end of vote"
        );
        require(
            balances[msg.sender] >= _amount,
            "DAO: The withdrawal amount is too large"
        );

        token.safeTransfer(msg.sender, _amount);
        balances[msg.sender] -= _amount;

        emit Withdraw(msg.sender, _amount);
    }

    /** @dev Create new proposal.
     * @param _recipient The address of the contract to be be called.
     * @param _description Proposal description.
     * @param _byteCode ByteCode to execute if proposal will pass.
     * @return _proposalId New proposal ID.
     */
    function newProposal(
        address _recipient,
        string memory _description,
        bytes memory _byteCode
    ) external payable returns (uint256 _proposalId) {
        require(
            token.balanceOf(msg.sender) > 0,
            "DAO: You are not a token owner"
        );

        Proposal storage proposal = proposals[proposalId];

        proposal.creator = msg.sender;
        proposal.recipient = _recipient;
        proposal.description = _description;
        proposal.proposalHash = _byteCode;
        proposal.votingDeadline = block.timestamp + votingPeriod;
        proposal.open = true;

        emit ProposalCreated(_recipient, msg.sender, _byteCode, proposalId);

        proposalId++;

        return proposalId - 1;
    }

    /** @dev Get proposal information.
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

    /** @dev Lock user's tokens to the contract to vote for the proposal.
     * @param _proposalId Id of the calling proposal.
     */
    function vote(uint256 _proposalId)
        external
        proposalInProgress(_proposalId)
        proposalExist(_proposalId)
        proposalIsOpened(_proposalId)
    {
        require(
            balances[msg.sender] > 0 ||
                delegatedVoting[_proposalId][msg.sender].delegated > 0,
            "DAO: You have not enought tokens deposited for voting"
        );

        _distributeTokensForVoting(_proposalId);

        emit Voted(_proposalId, msg.sender);
    }

    /** @dev Return tokens to user from DAO contract after voting.
     * @param _proposalId Id of the calling proposal.
     */
    function unVote(uint256 _proposalId) external shouldBeAVoter(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        uint256 voterAmount = proposal.voters[msg.sender];

        balances[msg.sender] += voterAmount;
        proposal.sum -= voterAmount;
        proposal.voters[msg.sender] = 0;

        emit UnVoted(_proposalId, msg.sender);
    }

    /** @notice Delegating votes to provided address for a specific proposal.
     * @param _proposalId Id of the calling proposal.
     * @param _to Address to delegate to.
     */
    function delegate(uint256 _proposalId, address _to)
        external
        proposalInProgress(_proposalId)
        proposalExist(_proposalId)
        proposalIsOpened(_proposalId)
    {
        require(
            msg.sender != _to,
            "DAO: You can't delegate tokens too yoursels"
        );

        delegates[_to][_proposalId].push(msg.sender);
        delegatedVoting[_proposalId][_to].delegated += balances[msg.sender];

        withdrawLock[msg.sender] = (proposals[_proposalId].votingDeadline) >
            withdrawLock[msg.sender]
            ? (proposals[_proposalId].votingDeadline)
            : withdrawLock[msg.sender];

        emit Delegate(_proposalId, msg.sender, _to);
    }

    /** @dev Execute proposal calldata if voting is successful.
     * @param _proposalId Id of the calling proposal.
     */
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

    /** @dev Changes voting rules such as min quorum and voting period time.
     * @param _minQuorum New minimum quorum (pct).
     * @param _votingPeriod New voting period (timestamp).
     */
    function changeVotingRules(uint256 _minQuorum, uint256 _votingPeriod)
        external
    {
        require(
            daoOwner == msg.sender,
            "DAO: Only DAO owner can modify proposal voting rules"
        );

        votingPeriod = _votingPeriod;
        minQuorum = _minQuorum;
    }

    /** @dev Get how many tokens proposal has.
     * @param _proposalId Id of the calling proposal.
     */
    function getProposalBalance(uint256 _proposalId)
        external
        view
        returns (uint256)
    {
        return proposals[_proposalId].sum;
    }

    /** @dev Get how many tokens user has on DAO.
     */
    function getVoterDaoBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /** @dev Desctribute tokens for a voting.
     * @param _proposalId Id of the calling proposal.
     */
    function _distributeTokensForVoting(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        uint256 _amount = balances[msg.sender] +
            delegatedVoting[_proposalId][msg.sender].delegated;

        proposals[_proposalId].voters[msg.sender] = _amount;

        proposals[_proposalId].sum += _amount;

        withdrawLock[msg.sender] = (proposal.votingDeadline) >
            withdrawLock[msg.sender]
            ? (proposal.votingDeadline)
            : withdrawLock[msg.sender];
    }

    /** @dev Close proposal.
     * @param _proposalId Id of the calling proposal.
     * @param _result True if successful voting, false if is not.
     */
    function _closeProposal(uint256 _proposalId, bool _result) internal {
        proposals[_proposalId].open = false;

        emit ProposalClosed(
            _proposalId,
            proposals[_proposalId].description,
            _result
        );
    }

    /** @dev Close successful proposal.
     * @param _proposalId Id of the calling proposal.
     * @return _success Status of closing proposal.
     */
    function _closeSuccessfulProposal(uint256 _proposalId)
        internal
        returns (bool _success)
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

    /** @dev Close outdated proposal.
     * @param _proposalId Id of the calling proposal.
     * @return _success Status of closing proposal.
     */
    function _closeOutdatedProposal(uint256 _proposalId)
        internal
        returns (bool _success)
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

    /** @dev Check enough quorum.
     * @param _proposalId Id of the calling proposal.
     */
    function _isProposalHasEnoughQuorum(uint256 _proposalId)
        internal
        view
        returns (bool)
    {
        uint256 totalSupply = token.totalSupply();

        return
            proposals[_proposalId].sum >= (((totalSupply / 100) * minQuorum));
    }

    /** @dev Check if proposal deadline passed.
     * @param _proposalId Id of the calling proposal.
     */
    function _isProposalDeadlinePassed(uint256 _proposalId)
        internal
        view
        returns (bool)
    {
        return block.timestamp > proposals[_proposalId].votingDeadline;
    }

    /** @dev  Execute proposal.
     * @param _proposalId Id of the calling proposal.
     */
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
}
