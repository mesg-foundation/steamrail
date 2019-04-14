pragma solidity >=0.5.0 <0.6.0;
import "./NodeProvider.sol";

contract Executions {

  /**
    Enums
   */

  enum State { Created, Submitted, Verified }

  /**
    Structures
   */

  struct Execution {
    uint256 executionId;
    uint256 serviceId;
    bytes task;
    State state;
    bytes inputs;
    bytes outputs;
    bool verified;
    address submitter;
    address[] verifiers;
    address[] verifiersAgree;
    address[] verifiersDisagree;
    uint256 consensus;
  }

  /**
    State variables
   */

  Execution[] public executions;
  NodeProvider public nodeProvider;

  /**
    Events
   */

  event Created(
    uint256 indexed executionId
  );

  event Submitted(
    uint256 indexed executionId
  );

  event Verified(
    uint256 indexed executionId
  );

  /**
    Constructor
   */

  constructor(NodeProvider _nodeProvider) public {
    nodeProvider = _nodeProvider;
  }

  /**
    Views
   */

  function executionsLength()
    external view
    returns (uint256 length)
  {
    return executions.length;
  }

  function executionsVerifiers(
    uint256 executionId
  ) 
    external view
    returns (address[] memory verifiers)
  {
    return executions[executionId].verifiers;
  }

  function executionsVerifiesAgree(
    uint256 executionId
  )
    external view
    returns (address[] memory verifiersAgree)
  {
    return executions[executionId].verifiersAgree;
  }

  function executionsVerifiersDisagree(
    uint256 executionId
  )
    external view
    returns (address[] memory verifiersDisagree)
  {
    return executions[executionId].verifiersDisagree;
  }

  /**
    Functions
   */

  function create(
    uint256 serviceId,
    bytes calldata task,
    bytes calldata inputs,
    // address submitter,
    // address[] calldata verifiers,
    uint256 nbrValidator,
    uint256 consensus
  ) external {
    // require(verifiers.length >= consensus, "not enough verifiers compared to required consensus");
    uint256 executionId = executions.length;
    address[] memory nodes = nodeProvider.pickNodes(serviceId, nbrValidator + 1);

    address submitter = nodes[0];
    address[] memory verifiers = new address[](nbrValidator);
    for(uint256 i = 0; i < nodes.length - 1; i++) {
      verifiers[i] = nodes[i + 1];
    }
    address[] memory emptyAddress;
    executions.push(Execution(
      executionId,
      serviceId,
      task,
      State.Created,
      inputs,
      "",
      false,
      submitter,
      verifiers,
      emptyAddress,
      emptyAddress,
      consensus
    ));
    emit Created(executionId);
  }

  // TODO: require a signature from the submitter based on the execution's inputs.
  function submit(
    uint256 executionId,
    bytes calldata outputs
  ) external {
    Execution storage exec = executions[executionId];
    require(exec.state == State.Created, "execution is not in created state");
    require(exec.submitter == msg.sender, "sender is not allowed to submit this execution");
    exec.outputs = outputs;
    exec.state = State.Submitted;
    emit Submitted(executionId);
  }

  // TODO: require a signature from the verifier based on the execution's outputs and maybe the submitter's address or signature.
  function verify(
    uint256 executionId,
    bool valid
  ) external {
    Execution storage exec = executions[executionId];
    require(exec.state == State.Submitted, "execution is not in submitted state");
    bool allowed = false;
    for (uint i = 0; i < exec.verifiers.length; i++){
      if(exec.verifiers[i] == msg.sender) {
        allowed = true;
        break;
      }
    }
    require(allowed, "sender is not allowed to verify this execution");
    if (valid) {
      exec.verifiersAgree.push(msg.sender);
    } else {
      exec.verifiersDisagree.push(msg.sender);
    }
    if (exec.verifiersAgree.length == exec.consensus) {
      exec.verified = true;
      exec.state = State.Verified;
      emit Verified(executionId);
    }
  }
}
