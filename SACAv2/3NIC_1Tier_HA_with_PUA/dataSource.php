<?
class dataSource
{
    protected $sourceType;
    protected $sourceValue;
    protected $ds;

    const SOURCE_MCPD = 0;
    const SOURCE_TEMPLATE = 1;

    public function __construct( $sourceType = dataSource::SOURCE_MCPD, $sourceValue = NULL )
    {
        $this->sourceType = $sourceType;
        $this->sourceValue = $sourceValue;

        switch( $this->sourceType )
        {
            case dataSource::SOURCE_TEMPLATE:
                $this->ds = new sourceTemplate( $this->sourceValue );
            break;
            default:
                $this->ds = new sourceMCPD_D( $this->sourceValue );
        }
    }

    public static function getHash( $type, $name )
    {
        return $this->source->getHash($type,$name);
    }
}

class sourceTemplate
{
    // point

    private $hash;

    public function __construct( $sourceValue )
    {
        $this->hash = $sourceValue;
    }

    public function isWritable(){ return false; }

    // point

    public function getHash( $type, $name )
    {
        return $this->getHashC( $type, array( "name" => $name ) );
    }

    public function getHashC( $type, $criteriaArray = array() )
    {
        if( empty($type)){
            return NULL;
        }

        foreach( $this->hash as $hash ){
            if( $hash["objectType"] == $type ){

                $passed = true;
                foreach( $criteriaArray as $k=>$v){
                    if( $hash[$k] != $v ){
                        $passed = false;
                        continue;
                    }
                }

                if( $passed )
                {
                    return $hash;
                }
            }
        }
        return NULL;
    }

    public function getAllHashes( $type, $criteriaArray = array() )
    {
        if( empty($type)){
            return NULL;
        }

        $ret = array();

        foreach( $this->hash as $hash ){
            if( $hash["objectType"] == $type ){

                $passed = true;
                foreach( $criteriaArray as $k=>$v){
                    if( $hash[$k] != $v ){
                        $passed = false;
                        continue;
                    }
                }

                if( $passed ){
                    $ret[] = $hash;
                }
            }
        }

        return $ret;
    }

    // create

    public function create( $type )
    {
        throw new Exception(__METHOD__."Unable to create object inside readonly datasource");
    }

    public function patchPartition( $name, $newPartition, $oldPartition){
        return $name;
    }

}

class sourceMCPD
{
    public static $mode;
    public static $dllLoaded;
    public static $readOnly = false;
    public static $cookiePartition = "";
    public static $userPartition = "";
    public static $ruser;
    public static $role;

    private static $unfilteredTypes = array( "user_role_partition",
            "auth_user", "auth_partition", "module_allocation", "license_blob" );

    const MODE_GUI = 0;
    const MODE_SYSCALLD = 1;
    const MODE_ROOTSHELL = 2;
    const MODE_UNKNOWN = 3;

    const MAXMCPNAMELENGTH = 144; // must be in sync: validate::MAXMCPNAMELENGTH - 6
    const HALFMCPNAMELENGTH = 72; // must be in sync: sourceMCPD::HALFMCPNAMELENGTH / 2

    public static function isReadOnly(){
        return self::$readOnly;
    }

    public static function log( $s )
    {
        if( isset( $GLOBALS["logger"] ) ){
            $GLOBALS["logger"]->out( $s );
        }
    }

    public static function findMode()
    {
/*
ob_start();
echo("server = "); print_r( $_SERVER );
echo("globals = "); print_r( $GLOBALS );
echo("env = "); print_r( $_ENV );
echo("cookie = "); print_r( $COOKIE );
$v = ob_get_contents();
ob_end_clean();
//self::log("findPartition ".$v);
*/
        //self::log("findMode _ENV[REMOTEUSER]='".$_ENV["REMOTEUSER"]."'");
        //self::log("findMode _SERVER[REMOTE_USER]='".$_SERVER["REMOTE_USER"]."'");
        //self::log("findMode _SERVER[USER]='".$_SERVER["USER"]."'");

        //self::log("findMode _COOKIE[F5_CURRENT_PARTITION]='".$_COOKIE["F5_CURRENT_PARTITION"]."'");
        //self::log("findMode _SERVER[HTTP_COOKIE]='".$_SERVER["HTTP_COOKIE"]."'");
        //self::log("findMode _ENV[MANUAL_COOKIE_PARTITION]='".$_ENV["MANUAL_COOKIE_PARTITION"]."'");

        if( !empty( $_SERVER["REMOTE_USER"] ) && ( !empty( $_COOKIE["F5_CURRENT_PARTITION"] ) || strpos($_SERVER["HTTP_COOKIE"],"F5_CURRENT_PARTITION") !== FALSE ) ){
            return sourceMCPD::MODE_GUI;
        }
        if( !empty( $_ENV["REMOTEUSER"] ) && $_ENV["REMOTEUSER"] == "root" ){
            return sourceMCPD::MODE_ROOTSHELL;
        }
        if( !empty( $_ENV["REMOTEUSER"] ) && !empty( $_SERVER["USER"] ) && $_ENV["REMOTEUSER"] == $_SERVER["USER"] ){
            return sourceMCPD::MODE_SYSCALLD;
        }

        //return sourceMCPD::MODE_UNKNOWN;
        return sourceMCPD::MODE_SYSCALLD;
    }

    public static function getRole()
    {
        return sourceMCPD::$role;
    }

    public static function isAdminRole()
    {
        //if(sourceMCPD::getRole() == 0) { // is role value system administrator?
        //    return TRUE;
        //} else {
        //    return FALSE;
       //}
       return TRUE;
    }

    public static function findUser()
    {
        $user = "";

        switch( sourceMCPD::$mode )
        {
            case sourceMCPD::MODE_GUI:
                 $user = $_SERVER["REMOTE_USER"];
            break;
            case sourceMCPD::MODE_SYSCALLD:
                 $user = $_ENV["REMOTEUSER"];
            break;
            case sourceMCPD::MODE_ROOTSHELL:
                 $user = ( $_ENV["REMOTEUSER"] == "root" ? "admin" : $_ENV["REMOTEUSER"] );
            break;
            case sourceMCPD::MODE_UNKNOWN:
            default:
                //throw new Exception(__METHOD__."Unknown user mode sourceMCPD::MODE_UNKNOWN");
                $user = $_ENV["REMOTEUSER"];
            break;
        }

        return $user;
    }

    public static function getProvision()
    {
        sourceMCPD::elevate(TRUE);
        $hashes = sourceMCPD::getAllHashes("module_allocation");
        sourceMCPD::elevate(FALSE);

        $ret = [];
        foreach($hashes as $hash){
            $ret[$hash["name"]] = $hash;
        }
        return $ret;
    }

    public static function isProvision( $moduleName )
    {
        $hashes = sourceMCPD::getProvision();
        if(is_array($hashes[$moduleName])){
            return $hashes[$moduleName]["provision_level"] > 1;
        }
        return false;
    }

    public static function findCookiePartition()
    {
        $cookiePartition = "Common";

        if( !empty( $_COOKIE ) && !empty( $_COOKIE["F5_CURRENT_PARTITION"] ) ){
            $cookiePartition = $_COOKIE["F5_CURRENT_PARTITION"];
        }
        elseif( !empty( $_SERVER ) && !empty( $_SERVER["HTTP_COOKIE"] ) && strpos($_SERVER["HTTP_COOKIE"],"F5_CURRENT_PARTITION") !== FALSE ){
            preg_match( '/F5_CURRENT_PARTITION=([^;]*)/', $_SERVER["HTTP_COOKIE"], $matches );
            $cookiePartition = $matches[1];
        }
        elseif( !empty( $_ENV["MANUAL_COOKIE_PARTITION"] ) ){
            $cookiePartition = $_ENV["MANUAL_COOKIE_PARTITION"];
        }

        $cookiePartition = str_replace( array( "\"", "\\" ), "", $cookiePartition );

        if( $cookiePartition != "[All]" && ( $phash = sourceMCPD::getHashC( "auth_partition", array( "name" => $cookiePartition ) ) ) === NULL ) {
            throw new Exception(__METHOD__." No partition with name ".$cookiePartition);
        }

        return $cookiePartition;
    }

    // for policy only
    public static function isPartitionRO( $objectPartition )
    {
        // no partition specified
        if( empty( $objectPartition ) ){
            return true;
        }

        // permanent read only case
        if( sourceMCPD::$cookiePartition == "[All]" ){
            return true;
        }

        return ( $objectPartition != sourceMCPD::$cookiePartition );
    }

/*
<token id="ROLE_ADMINISTRATOR" value="0"/> -rw
<token id="ROLE_PARTITION_EDITOR" value="100"/> - rw
<token id="ROLE_EDITOR" value="200"/> <!-- currently not implemented --> - rw
<token id="ROLE_APPLICATION_EDITOR" value="300"/> - rw
<token id="ROLE_OPERATOR" value="400"/> - r/o
<token id="ROLE_CERTIFICATE_MANAGER" value="500"/> - r/o
<token id="ROLE_USER_MANAGER" value="600"/> - r/o
<token id="ROLE_GUEST" value="700"/> - r/o
<token id="ROLE_APPLICATION_SECURITY_POLICY_EDITOR" value="800"/> - r/o
*/
    public static function reloadDll(){
        sourceMCPD::$dllLoaded = false;
        sourceMCPD::loadDll();
    }

    public static function loadDll()
    {
        if(sourceMCPD::$dllLoaded){
            return;
        }

        //self::log("\n\n\n\n\n\n\n\n\n\n *** *** loadDll");

        sourceMCPD::$dllLoaded = true;
        //dl("php_bridge.so");

        //self::log( "loadDll dl(php_bridge.so)" );

        sourceMCPD::$mode = self::findMode();
        //self::log("loadDll sourceMCPD::mode=".sourceMCPD::$mode."");

        sourceMCPD::$ruser =  sourceMCPD::findUser();
        //self::log("loadDll sourceMCPD::ruser='".sourceMCPD::$ruser."'");

        coapi_login(sourceMCPD::$ruser);
        //self::log("loadDll coapi_login('".sourceMCPD::$ruser."')");

        sourceMCPD::$cookiePartition = sourceMCPD::findCookiePartition();
        //self::log("loadDll sourceMCPD::cookiePartition='".sourceMCPD::$cookiePartition."'");

        // david holmes is in da house
        /* if( ( $userPartitionHash = sourceMCPD::getHashC( "user_role_partition", array( "user" => sourceMCPD::$ruser ) ) ) === NULL ) {
            throw new Exception(__METHOD__." No user role data for ".sourceMCPD::$ruser);
        }
        sourceMCPD::$userPartition = $userPartitionHash["partition"];
        sourceMCPD::$role = $userPartitionHash["role"];

        */

        $urpa = file("/config/bigip/auth/userrolepartitions");
        array_shift($urpa);
        foreach($urpa as $urpl){
            $vec = explode(" ", trim($urpl));
            $partition = array_pop($vec);
            $role = array_pop($vec);
            $user = implode(" ", $vec);
            if($user === sourceMCPD::$ruser
            && ($partition == "[All]" || sourceMCPD::$cookiePartition == $partition)){
                sourceMCPD::$userPartition = $partition;
                sourceMCPD::$role = $role;
                break;
            }
        }

        //self::log("loadDll sourceMCPD::userPartition='".sourceMCPD::$userPartition."'");
        if((sourceMCPD::$cookiePartition != "[All]"
            && sourceMCPD::$userPartition != "[All]"
            && sourceMCPD::$cookiePartition != "Common"
            && sourceMCPD::$cookiePartition != sourceMCPD::$userPartition)){
            throw new Exception(__METHOD__." User '".sourceMCPD::$ruser ."' has no access rights to partition '".sourceMCPD::$cookiePartition."'");
        }

        // read only
        // 80 - auditor
        if( sourceMCPD::$role >= 400 && sourceMCPD::$role <= 800 || sourceMCPD::$role == 80){
            sourceMCPD::$readOnly = true;
        }

        if( sourceMCPD::$cookiePartition == "[All]" ){
            sourceMCPD::$readOnly = true;
        }

        if( sourceMCPD::$userPartition != "[All]" && sourceMCPD::$userPartition != "Common" && sourceMCPD::$cookiePartition == "Common" ){
            sourceMCPD::$readOnly = true;
        }

        //self::log("loadDll  sourceMCPD::readOnly='". sourceMCPD::$readOnly."'");

        // no access
        if( sourceMCPD::$userPartition != "[All]" && sourceMCPD::$cookiePartition != "Common" && sourceMCPD::$userPartition != sourceMCPD::$cookiePartition ){
            throw new Exception(__METHOD__."No access for user '".sourceMCPD::$ruser."' to partition '".sourceMCPD::$cookiePartition."'");
        }
    }

    public static function isWritable(){ return true; }

    public function __construct( $sourceValue )
    {
    }

    // elevations
    private static $elevateTrigger = FALSE;
    private static function elevate($direction = FALSE){
        coapi_login( $direction ? "admin" : sourceMCPD::$ruser);
    }

    public static function elevateTrigger($trigger){
        sourceMCPD::$elevateTrigger = (bool)($trigger);
    }

    // read
    public static $getStatsHashCTotalQuery = 0.0;
    public static $getStatsHashCTotalFetch = 0.0;

    public static function getStatsHashC($type, $criteria=[], $fetch=NULL)
    {
        sourceMCPD::loadDll();
        if( empty($type)){ return NULL; }

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }

            //$begin = microtime($true);
        $result = coapi_stats_query($type, $criteria);
            //$queryTime = microtime($true) - $begin;
            //$getStatsHashCTotalQuery += $time;

            //$begin = microtime($true);
        if(!empty($result)){
            $hash = (is_array_non_empty($fetch) ? coapi_fetch_lite($result, $fetch) : coapi_fetch($result));
        }
            //$fetchTime = microtime($true) - $begin;
            //$getStatsHashCTotalFetch += $time;

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

            //self::log("query time: {$queryTime} total: {$getStatsHashCTotalQuery}");
            //self::log("fetch time: {$fetchTime} total: {$getStatsHashCTotalFetch}");
            //self::log("getStatsHashC return=".serialize($hash));

        return $hash;
    }

    public static function getHash($type, $name, $fetch=NULL, $partitionFlt=TRUE)
    {
            //self::log("getHash '{$type}', '".IMEX::sjoin($criteria)."', '".IMEX::sjoin($fetch, $false)."'");
        if(empty($name) || empty($type)){ return NULL; }

        return sourceMCPD::getHashC($type, ["name" => $name], $fetch, $partitionFlt);
    }

    public static $getHashCTotalQuery = 0.0;
    public static $getHashCTotalFetch = 0.0;
    public static function getHashC($type, $criteria=[], $fetch=NULL, $partitionFlt=TRUE)
    {
            //self::log("getHashC '{$type}', '".IMEX::sjoin($criteria)."', '".IMEX::sjoin($fetch, $false)."'");
        if(empty($type)){ return NULL; }

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }
        $hash = NULL;
            //$begin = microtime($true);
        $result = coapi_query($type, $criteria);
            //$queryTime = microtime($true) - $begin;
            //$getHashCTotalQuery += $time;

            //$begin = microtime($true);
        if(!empty($result)){
            $hash = (is_array_non_empty($fetch) ? coapi_fetch_lite($result, $fetch) : coapi_fetch($result));
            if(!empty($hash) || $hash != NULL){
                $hash["__dstype"] = $type;
                $hash["__dsop"] = "getHashC";
            }
            if($partitionFlt && !in_array($type, sourceMCPD::$unfilteredTypes)
                && ($hash = sourceMCPD::partitionFilter($hash)) === NULL){
                $hash = NULL;
            }
        }

            //$fetchTime = microtime($true) - $begin;
            //$getHashCTotalFetch += $time;

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

            //self::log("query time: {$queryTime} total: {$getHashCTotalQuery}");
            //self::log("fetch time: {$fetchTime} total: {$getHashCTotalFetch}");
            //self::log("getHashC return=".serialize($hash));

        return $hash;
    }

    public static $getAllHashesTotalQuery = 0.0;
    public static $getAllHashesTotalFetch = 0.0;
    public static function getAllHashes($type, $criteria=[], $fetch=NULL, $partitionFlt=TRUE)
    {
            //self::log("getAllHashes '{$type}', '".serialize($criteria)."', '".serialize($fetch)."', '".(int)$partitionFlt."'");
        if( empty($type)){ return NULL; }

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }

        $hashes = NULL;

            //$begin = microtime($true);
        $result = coapi_query($type, $criteria);
            //$queryTime = microtime($true) - $begin;
            //$getAllHashesTotalQuery += $time;

            //$begin = microtime($true);
        if(!empty($result)){
            $hashes = [];
            // Call the lite function to fetch only attributes requested in the filter
            while($hash = (is_array_non_empty($fetch) ? coapi_fetch_lite($result, $fetch) : coapi_fetch($result))){
                if($partitionFlt && !in_array($type, sourceMCPD::$unfilteredTypes)
                    && ($hash = sourceMCPD::partitionFilter($hash)) === NULL){
                    continue;
                }
                $hash["__dstype"] = $type;
                $hash["__dsop"] = "getAllHashes ".is_array_non_empty($fetch) ? "light" : "normal";
                $hashes[] = $hash;
            }
        }
            //$fetchTime = microtime($true) - $begin;
            //$getAllHashesTotalFetch += $time;

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

            //self::log("query time: {$queryTime} total: {$getAllHashesTotalQuery}");
            //self::log("fetch time: {$fetchTime} total: {$getAllHashesTotalFetch}");
            //self::log("getAllHashes return=".serialize($hashes));

        return $hashes;
    }

    public static function countAll($type, $criteria=[])
    {
        //self::log("countAll '{$type}' '".serialize($criteria));
        if( empty($type)){ return NULL; }

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }

        $count = 0;
        $result = coapi_query($type, $criteria);
        if(!empty($result)){
            $count = coapi_count($result);
        }

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

        //self::log("countAll return={$count}");
        return $count;
    }

    // save
    public static function saveHash($hash)
    {
        //self::log("saveHash ".serialize($hash));
        sourceMCPD::checkCookieParititon();
        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }

        $res = coapi_save_ignore_unmatched($hash, sourceMCPD::$cookiePartition);

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

        //self::log("saveHash return=".$res);
        return $res;
    }

    public static function saveDeleteAllHashes($saveHashes, $deleteHashes){
        //
        if(empty($saveHashes)){
            return sourceMCPD::delete($deleteHashes);
        }else{
            if(!empty($deleteHashes)){
                $deleteHashes = sourceMCPD_D::clearHashes($deleteHashes);
                coapi_delete_on_save($deleteHashes, sourceMCPD::$cookiePartition);
            }
            return sourceMCPD::saveAllHashes(sourceMCPD_D::clearHashes($saveHashes));
        }
    }

    public static function saveAllHashes($hashes)
    {
        //self::log("saveAllHashes ".serialize($hashes));
        sourceMCPD::checkCookieParititon();
        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }

        $res = coapi_save_ignore_unmatched($hashes, sourceMCPD::$cookiePartition);

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

        //self::log("saveAllHashes return=".$res);
        return $res;
    }

    // delete
    public static function delete($hash)
    {
        //self::log("delete ".serialize($hash));
        sourceMCPD::checkCookieParititon();
        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }


        $res = coapi_delete($hash, sourceMCPD::$cookiePartition);

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

        //self::log("delete return=".$res);
        return $res;
    }

    // create

    public static function create($type, $criteria=[])
    {
        //self::log("create '{$type}' ".serialize($criteria));
        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(TRUE); }
        if(!is_array($criteria)){ $criteria = []; }

        $res = coapi_create($type);
        if(is_array($res)){
            foreach($criteria as $k=>$v){
                $res[$k] = $v;
            }
            $res["__dstype"] = $type;
            $res["__dsop"] = "create";
        }

        if(!sourceMCPD::$elevateTrigger){ sourceMCPD::elevate(FALSE); }

        //self::log("create return=".serialize($res));
        return $res;
    }

    public static function error()
    {
        return coapi_errstr();
    }

    public static function checkCookieParititon()
    {
       if(empty(sourceMCPD::$cookiePartition) || sourceMCPD::$cookiePartition == "[All]"){
            throw new Exception(__METHOD__." Wrong partition '".sourceMCPD::$cookiePartition."'to saveAll");
       }
    }

    // what to do with this???
    /* this function should be deleted out */
    public static function getNewName($type, $fullNameTemplate, $testProposedFirst=false)
    {
        return sourceMCPD::getNewNameWithArray($type, $fullNameTemplate, $testProposedFirst);
    }

    public static function getNewNameWithArray($type, $foldernameTemplate, $testProposedFirst=false, $names=[])
    {
        if(!is_array($names)){ $names = []; }

        // remove unreadable symbols
        $foldernameTemplate = eregi_replace("^[^a-z0-9_/-]+","", $foldernameTemplate);
        if(class_exists("eContainer")){ eContainer::log("dataSource::getNewNameWithArray", "orig: $type, '$foldernameTemplate'"); }

        // split parititon/name
        list($partitionTemplate, $nameTemplate) = cmiName::split($foldernameTemplate);

        // name.exts support
        $postfix = "";
        if(($pos = strpos($nameTemplate, ".")) > 1 && $pos > strlen($nameTemplate)-6){ //.jpeg or .gif
            $postfix = substr($nameTemplate, $pos);
            $nameTemplate = substr($nameTemplate, 0, $pos);
        }

        // more than two _x
        $nameTemplate = uniquenessEnforce::removeExtra_($nameTemplate);

        if(class_exists("eContainer")){
            eContainer::log("dataSource::getNewNameWithArray", "split: '$partitionTemplate' '$nameTemplate' '$postfix'");
        }

        // if name is too big
        if(strlen($foldernameTemplate) > self::MAXMCPNAMELENGTH){
            $partitionTemplateLen = strlen($partitionTemplate);
            $nameTemplate = substr($nameTemplate, 0, self::HALFMCPNAMELENGTH-$partitionTemplateLen).substr($nameTemplate, -self::HALFMCPNAMELENGTH+$partitionTemplateLen);
            if(class_exists("eContainer")){ eContainer::log("dataSource::getNewNameWithArray", "shorten: $nameTemplate" ); }
        }

        // test propepsed first
        $newFoldernameTemplate = cmiName::join($partitionTemplate, $nameTemplate);
        if($testProposedFirst){
            $result = coapi_query($type, ["name" => $newFoldernameTemplate.$postfix]);
            $count = ($result === NULL) ? 0 : coapi_count($result);
            if( $count == 0 && !in_array($newFoldernameTemplate.$postfix, $names) ){
                return $newFoldernameTemplate.$postfix;
            }
        }

        // start with index
        $index = 1;
        do{
            $newFoldername = $newFoldernameTemplate."_".($index++).$postfix;
            $count = (($result = coapi_query($type, ["name" => $newFoldername])) === NULL ? 0 : coapi_count($result));
        }
        while($count > 0 || in_array($newFoldername, $names));

        if(class_exists("eContainer")){ eContainer::log("dataSource::getNewNameWithArray", "return: $newFoldername" ); }

        return $newFoldername;
    }

    public static function saveConfigFile()
    {
        coapi_persist_all();
    }

    public static function partitionFilter($hash)
    {
        if(sourceMCPD::$readOnly){
            return $hash;
        }
        //self::log( "partitionFilter: hash[name]='". $hash["name"]."' hash[partition_id]='". $hash["partition_id"] . "' sourceMCPD::cookiePartition='" . sourceMCPD::$cookiePartition. "' sourceMCPD::$userPartition='".sourceMCPD::$userPartition."'" );

        if(is_array_non_empty($hash)){
            switch( sourceMCPD::$cookiePartition ){
                case "Common":
                    // only Common
                    if( $hash["partition_id"] == sourceMCPD::$cookiePartition || strpos($hash["folder_name"], sourceMCPD::$cookiePartition) == 1 ) {
                        return $hash;
                    }
                break;
                default:
                    // this and common
                    if( ( $hash["partition_id"] == "Common" || strpos($hash["folder_name"], "Common" ) == 1 )
                        || $hash["partition_id"] == sourceMCPD::$cookiePartition /* == sourceMCPD::$userPartition */ ) {
                        return $hash;
                    }
                break;
            }
        }

        return NULL;
    }

    public static function patchPartition( $name, $newPartition, $oldPartition="" ){
        if( strpos( $name, "/" ) === FALSE ){
            $name = cmiName::join($newPartition, $name);
        }
        return $name;
    }
}

// dynamic version to avoid all E_STRICT notices
class sourceMCPD_D
{
    public function __construct( $sourceValue ){ }
    public function isReadOnly(){ return sourceMCPD::isReadOnly(); }
    public function isPartitionRO( $objectPartition ){ return sourceMCPD::isPartitionRO( $objectPartition ); }
    public function isWritable(){ return true; }

    public function getStatsHashC( $type, $criteriaArray ){ return sourceMCPD::getStatsHashC( $type, $criteriaArray ); }

    // Quick single transaction support
    public $hashes = [];
    public $transactional = FALSE;
    private function __addHashes( $hashes, $single=TRUE ){
        if( !$this->transactional ){ return $hashes; }
        //
        $single = ( $single || !is_array( $hashes ) );
        if( $single ){ $hashes = [ $hashes ]; }

        foreach( $hashes as &$hash ){
            if( $hash !== NULL ){
                $c = count( $this->hashes );
                $hash["__dsindex"] = $c;
                $hash["__dsstate"] = "r";
                $this->hashes[$c] = $hash;
            }
        }

        if( $single ){ $hashes = $hashes[0]; }
        return $hashes;
    }
    private function __changeStateHashes( $mode, $hashes, $single=TRUE ){
        //
        $single = ( $single || !is_array( $hashes ) || !is_array( $hashes[0] ) );
        if( $single ){ $hashes = [ $hashes ]; }
        //
        if( !$this->transactional ){
            foreach( $hashes as &$hash ){
                if( is_array($hash) ){
                    $hash["__dsstate"] = $mode;
                }
            }
            return $this->__executeHashes( ( $single ? $hashes[0] : $hashes ), $single );
        }
        //
        foreach( $hashes as $hash ){
            if( is_array($hash) ){
                foreach( $hash as $k=>$v ){
                    if( strlen($k) > 2 && substr( $k, 0, 2 ) != "__" ){
                        $this->hashes[ $hash["__dsindex"] ][ $k ] = $v;
                    }
                }
                $this->hashes[ $hash["__dsindex"] ]["__dsstate"] = $mode;
            }
        }
        //
        return TRUE;
    }
    public function executeTransactional(){
        return $this->__executeHashes( $this->hashes );
    }

    public function __error()
    {
        return sourceMCPD::error();
    }

    public static function clearHashes($hashes){
        if(is_array($hashes)){
            foreach($hashes as &$hash){
                if(!is_array($hash)){ continue; }
                foreach($hash as $k=>$v){
                    if(strpos($k,"__")===0){
                        unset($hash[$k]);
                    }
                }
            }
        }
        return $hashes;
    }

    public function __executeHashes( &$hashes, $single=false ){
        //
        $single = ( $single || !is_array( $hashes ) || !is_array( $hashes[0] ) );
        if( $single ){ $hashes = [ $hashes ]; }
        $delHash = [];
        $totalHash = [];
        //
        foreach($hashes as &$hash){
            if( is_array( $hash ) ){
                switch( $hash["__dsstate"] ){
                    case "d":
                        $delHash[] = $hash;
                        $totalHash[] = $hash;
                    break;
                    case "s":
                        $totalHash[] = $hash;
                    break;
                }
                $hash["__dsstate"] = "r";
            }

        }
        if(!empty($totalHash)){
            if(!empty($delHash)){
                // collect res?
                $delHash = self::clearHashes($delHash);
                $res = coapi_delete_on_save($delHash, sourceMCPD::$cookiePartition);
            }
            $totalHash = self::clearHashes($totalHash);
            $res = coapi_save_ignore_unmatched( $totalHash, sourceMCPD::$cookiePartition );
            return $res;
        }
        return TRUE;
    }

    // read hashes
    public function getHash($type, $name, $fetch=NULL, $partitionFlt=TRUE){
        return $this->__addHashes(sourceMCPD::getHash($type, $name, $fetch));
    }
    public function getHashC($type, $criteria=[], $fetch=NULL, $partitionFlt=TRUE) {
        return $this->__addHashes(sourceMCPD::getHashC($type, $criteria, $fetch, $partitionFlt));
    }
    public function getAllHashes($type, $criteria=[], $fetch=NULL, $partitionFlt=TRUE) {
        return $this->__addHashes(sourceMCPD::getAllHashes($type, $criteria, $fetch, $partitionFlt), FALSE);
    }

    // save
    public function saveHash( $hash ) {
        return $this->__changeStateHashes( "s", $hash );
    }
    public function saveAllHashes( $hashes ) {
        return $this->__changeStateHashes( "s", $hashes, FALSE );
    }
    public function delete( $hash ) {
        return $this->__changeStateHashes( "d", $hash, FALSE );
    }
    public function create( $type, $criteriaArray = array() ){
        return $this->__addHashes( sourceMCPD::create( $type, $criteriaArray ) );
    }

    // aux
    public function getNewName( $type, $fullNameTemplate, $testProposedFirst = false ){ return sourceMCPD::getNewName( $type, $fullNameTemplate, $testProposedFirst ); }
    public function getNewNameWithArray( $type, $fullNameTemplate, $testProposedFirst = false, $namesArray = array() ) { return sourceMCPD::getNewName( $type, $fullNameTemplate, $testProposedFirst, $namesArray ); }

    public function patchPartition( $name, $newPartition, $oldPartition="" ){ return sourceMCPD::patchPartition( $name, $newPartition, $oldPartition ); }
}

/********************************************************************************************************
* RUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUN
********************************************************************************************************/

sourceMCPD::loadDll();

?>
