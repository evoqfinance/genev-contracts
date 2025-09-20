// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {MarketParamsLib} from "../src/libraries/MarketParamsLib.sol";
import {MetaMorphoV1_1Factory} from "../src/metamorpho-v1.1/MetaMorphoV1_1Factory.sol";
import {IMetaMorphoV1_1, MarketAllocation} from "../src/metamorpho-v1.1/interfaces/IMetaMorphoV1_1.sol";
import {IMorpho, MarketParams, Id} from "../src/interfaces/IMorpho.sol";
import {BaseConfig} from "../config/BaseConfig.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWKLAY} from "../src/interfaces/IWKLAY.sol";

/// @title DeployMetaMorpho
/// @notice Script to deploy MetaMorpho contracts and vaults
/// @author Morpho Labs
contract DeployMetaMorpho is Script, BaseConfig {
    using MarketParamsLib for MarketParams;

    /// @notice The address that will be set as the owner of the MetaMorpho vaults
    address public owner;
    /// @notice The address of the deployed Morpho contract
    address public morphoAddress;

    address public oracleWKAIA_USDTAddress;
    address public oracleUSDT_WKAIAAddress;
    address public irmAddress;

    uint256 constant INITIAL_TIMELOCK = 0;
    bytes32 constant SIMPLE_SALT = bytes32(uint256(1));

    function setUp() public {
        // Set the owner address - you can modify this or set it via environment variable
        owner = vm.envOr("MORPHO_OWNER", address(msg.sender));
        morphoAddress = vm.envOr("MORPHO_ADDRESS", address(0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE));
        oracleWKAIA_USDTAddress = vm.envOr(
            "ORACLE_WKAIA_USDT_ADDRESS",
            address(0x2d251ADAb1C454a7D919605F4470C95A059BD782)
        );
        oracleUSDT_WKAIAAddress = vm.envOr(
            "ORACLE_USDT_WKAIA_ADDRESS",
            address(0xAC19A5197367E835BA4d88E2c93f96C5D19a8Ae5)
        );
        irmAddress = vm.envOr("IRM_ADDRESS", address(0x68B1D87F95878fE05B998F19b66F4baba5De1aed));

        // Ensure owner is not zero address
        require(owner != address(0), "Owner cannot be zero address");
    }

    /// @notice Deploys the MetaMorphoV1_1Factory contract
    /// @param morpho The address of the deployed Morpho contract
    /// @return factory The deployed MetaMorphoV1_1Factory instance
    function deployMetaMorphoFactory(address morpho) internal returns (MetaMorphoV1_1Factory factory) {
        factory = new MetaMorphoV1_1Factory(morpho);
        console.log("MetaMorphoV1_1Factory deployed at:", address(factory));
    }

    /// @notice Sets up a complete MetaMorpho vault with market configuration
    /// @param factory The MetaMorphoV1_1Factory instance
    /// @param vaultAsset The underlying asset for the vault
    /// @param vaultName The name of the vault
    /// @param vaultSymbol The symbol of the vault
    /// @param loanToken The loan token for the market
    /// @param collateralToken The collateral token for the market
    /// @param capAmount The cap amount for the market
    /// @param allocationAmount The allocation amount for reallocation
    /// @return vault The configured MetaMorpho vault instance
    function setupVault(
        MetaMorphoV1_1Factory factory,
        address vaultAsset,
        address oracle,
        address irm,
        string memory vaultName,
        string memory vaultSymbol,
        address loanToken,
        address collateralToken,
        uint256 capAmount,
        uint256 allocationAmount,
        uint256 depositAmount
    ) internal returns (IMetaMorphoV1_1 vault) {
        // Create the vault
        vault = factory.createMetaMorpho(owner, INITIAL_TIMELOCK, vaultAsset, vaultName, vaultSymbol, SIMPLE_SALT);

        console.log("MetaMorpho vault created at:", address(vault));
        console.log("Vault name:", vaultName);
        console.log("Vault symbol:", vaultSymbol);
        console.log("Underlying asset:", vaultAsset);

        // Set up market parameters
        MarketParams memory marketParams = MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: oracle,
            irm: irm,
            lltv: 0.8e18
        });

        vault.submitCap(marketParams, capAmount);
        vault.acceptCap(marketParams);

        Id[] memory ids = new Id[](1);
        ids[0] = marketParams.id();

        vault.setSupplyQueue(ids);

        IERC20(vaultAsset).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, owner);
        console.log("Vault deposited at:", depositAmount);

        // Set up allocations and reallocate
        MarketAllocation[] memory allocations = new MarketAllocation[](1);
        allocations[0] = MarketAllocation({marketParams: marketParams, assets: allocationAmount});
        vault.reallocate(allocations);

        console.log("Vault setup completed for:", vaultName);
    }

    /// @notice Deploy MetaMorpho factory and create vaults
    function run() public {
        vm.startBroadcast();

        // Deploy MetaMorphoV1_1Factory
        MetaMorphoV1_1Factory metaMorphoFactory = deployMetaMorphoFactory(morphoAddress);

        // Create and setup WKAIA vault
        setupVault(
            metaMorphoFactory,
            USDT, // vault asset
            oracleWKAIA_USDTAddress,
            irmAddress,
            "MetaMorpho Vault USDT",
            "MMUSDT",
            USDT, // loan token
            WKAIA, // collateral token
            10_000 * 1e6, // cap amount
            1 * 1e6, // allocation assets
            1 * 1e6 // deposit assets
        );

        // Create and setup USDT vault
        setupVault(
            metaMorphoFactory,
            WKAIA, // vault asset
            oracleUSDT_WKAIAAddress,
            irmAddress,
            "MetaMorpho Vault WKAIA",
            "MMWKAIA",
            WKAIA, // loan token
            USDT, // collateral token
            10_000 * 1e18, // cap amount
            1 * 1e18, // allocation assets
            1 * 1e18 // deposit assets
        );

        // MarketParams memory marketParams = MarketParams({
        //     loanToken: WKAIA,
        //     collateralToken: USDT,
        //     oracle: oracleAddress,
        //     irm: irmAddress,
        //     lltv: 0.8e18
        // });

        // IERC20(USDT).approve(address(morphoAddress), 10000 * 1e6);
        // IMorpho(morphoAddress).supplyCollateral(marketParams, 10000 * 1e6, owner, hex"");
        // IMorpho(morphoAddress).borrow(marketParams, 0.000001e18, 0, owner, owner);

        vm.stopBroadcast();
    }
}
