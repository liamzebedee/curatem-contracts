// pragma solidity ^0.5.5;

interface IRealitio {
    function askQuestion(uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
    function getContentHash(bytes32 questionId) external view returns (bytes32);
    function getOpeningTS(bytes32 questionId) external view returns (uint32);
    function resultFor(bytes32 questionId) external view returns (bytes32);
    function getBond ( bytes32 question_id ) external view returns ( uint256 );
    function submitAnswer ( bytes32 question_id, bytes32 answer, uint256 max_previous ) external payable;
    function notifyOfArbitrationRequest(bytes32 question_id, address requester, uint256 max_previous) external;
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) external;
}