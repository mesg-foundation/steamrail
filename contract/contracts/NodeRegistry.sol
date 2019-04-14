pragma solidity >=0.5.0 <0.6.0;
import "./itMapsLib.sol";
// pragma experimental ABIEncoderV2;

contract NodeRegistry {
  using itMaps for itMaps.itMapAddressUint;

  /**
    Structures
   */

  /**
    State variables
   */

  mapping(bytes32 => itMaps.itMapAddressUint) serviceIdToNodeToStake;

  /**
    Events
   */

  event Registered(
    bytes32 indexed serviceId,
    address indexed node,
    uint256 value
  );

  event Cancelled(
    bytes32 indexed serviceId,
    address indexed node
  );

  /**
    Views
   */

  function isRegistered(bytes32 serviceId, address node) public view returns (bool) {
    return serviceIdToNodeToStake[serviceId].contains(node);
  }

  function nodes(bytes32 serviceId) public view returns (address[] memory) {
    return serviceIdToNodeToStake[serviceId].keys;
  }

  function stake(bytes32 serviceId, address node) public view returns (uint256) {
    return serviceIdToNodeToStake[serviceId].get(node);
  }

  /**
    Public
   */

  function register(bytes32 serviceId) public payable {
    require(!serviceIdToNodeToStake[serviceId].contains(msg.sender), "node is already register for this service");
    serviceIdToNodeToStake[serviceId].insert(msg.sender, msg.value);
    emit Registered(serviceId, msg.sender, msg.value);
  }

  function cancel(bytes32 serviceId) public {
    require(serviceIdToNodeToStake[serviceId].contains(msg.sender), "node is not register for this service");
    msg.sender.transfer(serviceIdToNodeToStake[serviceId].get(msg.sender));
    serviceIdToNodeToStake[serviceId].remove(msg.sender);
    // Replace the element to delete and shift elements of the array.
    serviceIdToNodeToStake[serviceId].remove(msg.sender);
    emit Cancelled(serviceId, msg.sender);
  }

}
