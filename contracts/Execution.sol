pragma solidity >=0.5.0 <0.6.0;

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
    bytes service;
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

  /**
    Events
   */

  event Created(
    uint256 indexed executionId,
    bytes service,
    bytes task,
    bytes inputs
  );

  event Submitted(
    uint256 indexed executionId,
    bytes service,
    bytes task,
    bytes outputs
  );

  event Verified(
    uint256 indexed executionId,
    bytes service,
    bytes task
  );

  /**
    Views
   */

  function executionsLength()
    external view
    returns (uint256 length)
  {
    return executions.length;
  }

  /**
    Functions
   */

  function create(
    bytes calldata service,
    bytes calldata task,
    bytes calldata inputs,
    address submitter,
    address[] calldata verifiers,
    uint256 consensus
  ) external {
    require(verifiers.length < consensus, "Not enough verifiers compared to required consensus");
    uint256 executionId = executions.length;
    address[] memory emptyAddress;
    executions.push(Execution(
      executionId,
      service,
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
    emit Created(executionId, service, task, inputs);
  }

  function submit(
    uint256 executionId,
    bytes calldata outputs
  ) external {
    Execution storage exec = executions[executionId];
    require(exec.state == State.Created, "Execution is not in created state");
    require(exec.submitter == msg.sender, "Sender is not allowed to submit this execution");
    exec.outputs = outputs;
    exec.state = State.Submitted;
    emit Submitted(executionId, exec.service, exec.task, outputs);
  }

  function verify(
    uint256 executionId,
    bool valid
  ) external {
    Execution storage exec = executions[executionId];
    require(exec.state == State.Submitted, "Execution is not in submitted state");
    bool allowed = false;
    for (uint i = 0; i<exec.verifiers.length-1; i++){
      if(exec.verifiers[i] == msg.sender) {
        allowed = true;
        break;
      }
    }
    require(allowed, "Sender is not allowed to verify this execution");
    if (valid) {
      exec.verifiersAgree.push(msg.sender);
    } else {
      exec.verifiersDisagree.push(msg.sender);
    }
    if (exec.verifiersAgree.length == exec.consensus) {
      exec.verified = true;
      exec.state = State.Verified;
      emit Verified(executionId, exec.service, exec.task);
    }
  }
}
