pragma solidity >=0.5.0 <0.6.0;
import "./NodeProvider.sol";

contract Executions {

  /**
    Enums
   */

  enum State { Created, Executed, Validated, ValidationFailed }

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
    address submitter;
    address[] verifiers;
    address[] verifiersAgree;
    address[] verifiersDisagree;
    bool valid;
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
    uint256 indexed executionId,
    uint256 indexed serviceId,
    bytes task,
    bytes inputs,
    address indexed submitter
  );

  event Executed(
    uint256 indexed executionId,
    uint256 indexed serviceId,
    bytes task,
    bytes inputs,
    bytes outputs,
    address[] verifiers
  );

  event Verified(
    uint256 indexed executionId,
    uint256 indexed serviceId,
    bytes task,
    address indexed verifier,
    bool valid
  );

  event Validated(
    uint256 indexed executionId,
    uint256 indexed serviceId,
    bytes task,
    bytes outputs,
    address submitter,
    address[] verifiersAgree,
    address[] verifiersDisagree
  );

  event ValidationFailed(
    uint256 indexed executionId,
    uint256 indexed serviceId,
    bytes task,
    address submitter,
    address[] verifiersAgree,
    address[] verifiersDisagree
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
    uint256 nbrValidator
    // uint256 consensus
  ) external {
    // require(verifiers.length >= consensus, "not enough verifiers compared to required consensus");
    // require(consensus > nbrValidator / 2, "consensus should be greater than half of nbrValidator");
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
      submitter,
      verifiers,
      emptyAddress,
      emptyAddress,
      false
    ));
    emit Created(
      executionId,
      serviceId,
      task,
      inputs,
      submitter
    );
  }

  // TODO: require a signature from the submitter based on the execution's inputs.
  function submitOutputs(
    uint256 executionId,
    bytes calldata outputs
  ) external {
    Execution storage exec = executions[executionId];
    require(exec.state == State.Created, "execution is not in created state");
    require(exec.submitter == msg.sender, "sender is not allowed to submit this execution");
    exec.outputs = outputs;
    exec.state = State.Executed;
    emit Executed(
      executionId,
      exec.serviceId,
      exec.task,
      exec.inputs,
      outputs,
      exec.verifiers
    );
  }

  // TODO: require a signature from the verifier based on the execution's outputs and maybe the submitter's address or signature.
  function submitVerification(
    uint256 executionId,
    bool valid
  ) external {
    Execution storage exec = executions[executionId];
    require(exec.state == State.Executed, "execution is not in executed state");
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
    emit Verified(
      executionId,
      exec.serviceId,
      exec.task,
      msg.sender,
      valid
    );

    // check consensus
    if (exec.verifiersAgree.length + exec.verifiersDisagree.length < exec.verifiers.length) {
      return;
    }
    if (exec.verifiersAgree.length > exec.verifiersDisagree.length) {
      exec.valid = true;
      exec.state = State.Validated;
      emit Validated(
        executionId,
        exec.serviceId,
        exec.task,
        exec.outputs,
        exec.submitter,
        exec.verifiersAgree,
        exec.verifiersDisagree
      );
    } else {
      exec.valid = false;
      exec.state = State.ValidationFailed;
      emit ValidationFailed(
        executionId,
        exec.serviceId,
        exec.task,
        exec.submitter,
        exec.verifiersAgree,
        exec.verifiersDisagree
      );
    }
  }
}
