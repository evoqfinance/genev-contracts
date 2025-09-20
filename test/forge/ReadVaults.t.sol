// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Morpho} from "../../src/Morpho.sol";
import {IMorpho} from "../../src/interfaces/IMorpho.sol";
import {ORACLE_PRICE_SCALE} from "../../src/libraries/ConstantsLib.sol";
import {IMetaMorphoV1_1 as IMetaMorpho} from "../../src/metamorpho-v1.1/interfaces/IMetaMorphoV1_1.sol";
import {MetaMorphoV1_1 as MetaMorpho} from "../../src/metamorpho-v1.1/MetaMorphoV1_1.sol";
import {ReadVaults} from "../../src/lens/ReadVaults.sol";
import {OracleMock} from "../../src/mocks/OracleMock.sol";
import {FixedRateIrm} from "../../src/irm/fixed-rate-irm/FixedRateIrm.sol";
import {BaseConfig} from "../../config/BaseConfig.sol";
import {console2 as console} from "forge-std/console2.sol";
import {AccrualVault} from "../../src/lens/ReadVaults.sol";

contract ReadVaultsTest is Test, BaseConfig {
    IMorpho morpho;
    IMetaMorpho[] metaMorphos;
    address[] includedOwners;
    ReadVaults readVaults;

    function setUp() public {
        OracleMock oracle = new OracleMock();
        oracle.setPrice(ORACLE_PRICE_SCALE);

        FixedRateIrm fixedRateIrm = new FixedRateIrm();

        morpho = IMorpho(address(new Morpho(msg.sender)));

        IMetaMorpho metaMorpho0 = IMetaMorpho(
            address(new MetaMorpho(msg.sender, address(morpho), 0, WKAIA, "MetaMorpho Vault WKAIA", "MMWKAIA"))
        );
        IMetaMorpho metaMorpho1 = IMetaMorpho(
            address(new MetaMorpho(msg.sender, address(morpho), 0, USDT, "MetaMorpho Vault USDT", "MMUSDT"))
        );

        metaMorphos = [metaMorpho0, metaMorpho1];
        includedOwners = [msg.sender];

        readVaults = new ReadVaults();
        console.log("readVaults deployed at", address(readVaults));
    }

    function testReadVaults() public {
        AccrualVault[] memory accrualVaults = readVaults.getAccrualVaults(morpho, metaMorphos, includedOwners);
        console.log("accrualVaults length", accrualVaults.length);
    }
}
