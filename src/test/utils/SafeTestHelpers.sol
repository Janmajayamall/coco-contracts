import "./../../../lib/safe-contracts/contracts/GnosisSafe.sol";


contract SafeTestHelpers {
    function deploySafeSingleton() public returns (GnosisSafe _singleton){
        _singleton = new GnosisSafe();
    }


}