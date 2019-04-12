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
    State state;
    bytes inputs;
    bytes outputs;
    bool verified;
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
    bytes inputs
  );

  event Submitted(
    uint256 indexed executionId,
    bytes outputs
  );

  event Verified(
    uint256 indexed executionId
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
    bytes calldata inputs
  ) external {
    uint256 executionId = executions.length;
    executions.push(Execution(
      executionId,
      State.Created,
      inputs,
      "",
      false
    ));
    emit Created(executionId, inputs);
  }

  function submit(
    uint256 executionId,
    bytes calldata outputs
  ) external {
    executions[executionId].outputs = outputs;
    executions[executionId].state = State.Submitted;
    emit Submitted(executionId, outputs);
    require(exec.state == State.Created, "Execution is not in created state");
  }

  function verify(
    uint256 executionId
  ) external {
    executions[executionId].verified = true;
    executions[executionId].state = State.Verified;
    emit Verified(executionId);
    require(exec.state == State.Submitted, "Execution is not in submitted state");
  }
}
