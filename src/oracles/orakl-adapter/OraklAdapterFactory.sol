// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {OraklToChainlinkAdapter} from "./OraklToChainlinkAdapter.sol";
import {OraklRouterAdapter} from "./OraklRouterAdapter.sol";

/// @title OraklAdapterFactory
/// @notice Factory for deploying Orakl Network adapters
/// @author Morpho Labs
contract OraklAdapterFactory {
    /* EVENTS */

    /// @notice Emitted when a new OraklToChainlinkAdapter is created
    /// @param creator The address that created the adapter
    /// @param adapter The address of the created adapter
    /// @param oraklFeed The address of the Orakl feed used
    /// @param description The description of the feed
    event CreateOraklToChainlinkAdapter(
        address indexed creator,
        address indexed adapter,
        address indexed oraklFeed,
        string description
    );

    /// @notice Emitted when a new OraklRouterAdapter is created
    /// @param creator The address that created the adapter
    /// @param adapter The address of the created adapter
    /// @param oraklRouter The address of the Orakl router used
    /// @param feedName The name of the feed
    event CreateOraklRouterAdapter(
        address indexed creator,
        address indexed adapter,
        address indexed oraklRouter,
        string feedName
    );

    /* STORAGE */

    /// @notice Mapping to track deployed adapters
    mapping(address => bool) public isOraklAdapter;

    /* EXTERNAL */

    /// @notice Creates a new OraklToChainlinkAdapter
    /// @param oraklFeed The address of the Orakl Network FeedProxy
    /// @param description The description of the feed (e.g., "BTC/USD")
    /// @param salt A unique identifier for deterministic deployment
    /// @return adapter The address of the created adapter
    function createOraklToChainlinkAdapter(
        address oraklFeed,
        string calldata description,
        bytes32 salt
    ) external returns (OraklToChainlinkAdapter adapter) {
        adapter = new OraklToChainlinkAdapter{salt: salt}(oraklFeed, description);

        isOraklAdapter[address(adapter)] = true;

        emit CreateOraklToChainlinkAdapter(msg.sender, address(adapter), oraklFeed, description);
    }

    /// @notice Creates a new OraklRouterAdapter
    /// @param oraklRouter The address of the Orakl Network FeedRouter
    /// @param feedName The name of the feed (e.g., "BTC-USDT")
    /// @param salt A unique identifier for deterministic deployment
    /// @return adapter The address of the created adapter
    function createOraklRouterAdapter(
        address oraklRouter,
        string calldata feedName,
        bytes32 salt
    ) external returns (OraklRouterAdapter adapter) {
        adapter = new OraklRouterAdapter{salt: salt}(oraklRouter, feedName);

        isOraklAdapter[address(adapter)] = true;

        emit CreateOraklRouterAdapter(msg.sender, address(adapter), oraklRouter, feedName);
    }

    /// @notice Creates multiple OraklToChainlinkAdapters in a single transaction
    /// @param oraklFeeds Array of Orakl feed addresses
    /// @param descriptions Array of feed descriptions
    /// @param salts Array of unique identifiers for deterministic deployment
    /// @return adapters Array of created adapter addresses
    function createMultipleOraklToChainlinkAdapters(
        address[] calldata oraklFeeds,
        string[] calldata descriptions,
        bytes32[] calldata salts
    ) external returns (OraklToChainlinkAdapter[] memory adapters) {
        require(
            oraklFeeds.length == descriptions.length && descriptions.length == salts.length,
            "Arrays length mismatch"
        );

        adapters = new OraklToChainlinkAdapter[](oraklFeeds.length);

        for (uint256 i = 0; i < oraklFeeds.length; i++) {
            adapters[i] = new OraklToChainlinkAdapter{salt: salts[i]}(oraklFeeds[i], descriptions[i]);
            isOraklAdapter[address(adapters[i])] = true;

            emit CreateOraklToChainlinkAdapter(msg.sender, address(adapters[i]), oraklFeeds[i], descriptions[i]);
        }
    }

    /// @notice Creates multiple OraklRouterAdapters in a single transaction
    /// @param oraklRouter The address of the Orakl Network FeedRouter
    /// @param feedNames Array of feed names
    /// @param salts Array of unique identifiers for deterministic deployment
    /// @return adapters Array of created adapter addresses
    function createMultipleOraklRouterAdapters(
        address oraklRouter,
        string[] calldata feedNames,
        bytes32[] calldata salts
    ) external returns (OraklRouterAdapter[] memory adapters) {
        require(feedNames.length == salts.length, "Arrays length mismatch");

        adapters = new OraklRouterAdapter[](feedNames.length);

        for (uint256 i = 0; i < feedNames.length; i++) {
            adapters[i] = new OraklRouterAdapter{salt: salts[i]}(oraklRouter, feedNames[i]);
            isOraklAdapter[address(adapters[i])] = true;

            emit CreateOraklRouterAdapter(msg.sender, address(adapters[i]), oraklRouter, feedNames[i]);
        }
    }
}
