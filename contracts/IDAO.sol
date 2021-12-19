// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDAO {
    /** @notice Create new proposal.
     * @param _recipient The address of the contract to be be called.
     * @param _description Proposal description.
     * @param _byteCode ByteCode to execute if proposal will pass.
     * @return _proposalId New proposal ID.
     */
    function newProposal(
        address _recipient,
        string memory _description,
        bytes memory _byteCode
    ) external payable returns (uint256 _proposalId);

    /** @notice Get proposal information.
     * @param _proposalId Id of the calling proposal.
     * @return _description Proposal description.
     * @return _open Voting status, true if still voting, false if voting ends.
     * @return _sum Sum of voting tokens.
     */
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            string memory _description,
            bool _open,
            uint256 _sum
        );

    /** @notice Deposit tokens to DAO.
     * @param _amount Amount deposited tokens.
     */
    function deposit(uint256 _amount) external payable;

    /** @notice Withdraw tokens from DAO to user.
     * @param _amount Amount withdraw tokens.
     */
    function withdraw(uint256 _amount) external payable;

    /** @notice Lock user's tokens to the contract to vote for the proposal.
     * @param _proposalId Id of the calling proposal.
     */
    function vote(uint256 _proposalId) external;

    /** @notice Delegating votes to provided address for a specific proposal.
     * @param _proposalId Id of the calling proposal.
     * @param _to Address to delegate to.
     */
    function delegate(uint256 _proposalId, address _to) external;

    /** @notice Return tokens to user from DAO contract after voting.
     * @param _proposalId Id of the calling proposal.
     */
    function unVote(uint256 _proposalId) external;

    /** @notice Execute proposal calldata if voting is successful.
     * @param _proposalId Id of the calling proposal.
     */
    function executeProposal(uint256 _proposalId)
        external
        returns (bool _success);

    /** @dev Changes voting rules such as min quorum and voting period time.
     * @param _minQuorum New minimum quorum (pct).
     * @param _votingPeriod New voting period (timestamp).
     */
    function changeVotingRules(uint256 _minQuorum, uint256 _votingPeriod)
        external;

    /** @dev Get how many tokens proposal has.
     * @param _proposalId Id of the calling proposal.
     */
    function getProposalBalance(uint256 _proposalId)
        external
        view
        returns (uint256);

    /** @dev Get how many tokens user has on DAO.
     */
    function getVoterDaoBalance() external view returns (uint256);

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
    event Deposit(address _msgSender, uint256 _amount);
    event Withdraw(address _msgSender, uint256 _amount);
    event Voted(uint256 _proposalId, address indexed _voter);
    event UnVoted(uint256 _proposalId, address indexed _voter);
    event Delegate(
        uint256 _proposalId,
        address indexed _msgSender,
        address _to
    );
    event ProposalClosed(
        uint256 _proposalId,
        string _description,
        bool _result
    );
}
