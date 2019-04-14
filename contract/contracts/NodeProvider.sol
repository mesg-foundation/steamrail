pragma solidity >=0.5.0 <0.6.0;
import "./NodeRegistry.sol";

contract NodeProvider {

  /**
    State variables
   */

  NodeRegistry public nodeRegistry;

  /**
    Constructor
   */

  constructor(NodeRegistry _nodeRegistry) public {
    nodeRegistry = _nodeRegistry;
  }

  /**
    Functions
   */

  function pickNodes(uint256 serviceId, uint256 nbr) public view returns (address[] memory) {
    address[] memory nodes = nodeRegistry.nodes(serviceId);
    require(nodes.length >= nbr, "not enough nodes compared to required nbr");
    uint256 nodesLength = nodes.length;
    address[] memory selectedNodes = new address[](nbr);
    uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
    for(uint256 i = 0; i < nbr; i++) {
      uint256 index = pseudoRandom % nodesLength;
      selectedNodes[i] = nodes[index];
      nodes[index] = nodes[nodesLength - 1];
      nodesLength -= 1;
    }
    return selectedNodes;
  }

  function verifyNodes(uint256 serviceId, address[] memory nodes) public view returns (bool) {
    for(uint256 i = 0; i < nodes.length; i++) {
      if (!nodeRegistry.isRegistered(serviceId, nodes[i])) {
        return false;
      }
    }
    return true;
  }

}