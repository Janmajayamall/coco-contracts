import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";


contract SafeTestHelpers {
    function deploySingleton() public returns (GnosisSafe _singleton){
        _singleton = new GnosisSafe();
    }
}
