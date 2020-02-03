<?php
/**
 * extension source version
 */
$version = '1.3.1';

/**
 * dist filename
 */
$distFilenamePrefix = 'opencart-';
$distFilenameSuffix = '.ocmod';

/**
 * path within zip file
 * set to false to have source at the root of the zip file
 * a requirement in some systems to make the zip file installable
 * others require it to be lowercase without special characters
 */
$distFilenameRootDirName = false;

/**
 * Dragons below
 * Do not change
 */

/**
 * build config
 */
$placeholderName = 'Payment Gateway Cloud';
$hostname = $argv[1] ?? null;
$name = $argv[2] ?? null;
$debug = strpos(implode(' ', $argv), ' --debug') !== false;
$srcDir = 'src';
$buildDir = 'build';
$distDir = 'dist';

line();
highlight('Whitelabel Build Script');

/**
 * check workspace
 */
if (!realpath($srcDir)) {
    line();
    error('Source directory does not exist');
    exit;
}

/**
 * validate name input
 */
if (empty($name)) {
    line();
    error('Name must not be empty');
    usage();
    exit;
}

if (strlen($name) > 21) {
    line();
    error('Name must not be longer than 21 characters');
    usage();
    exit;
}

/**
 * validate domain input
 */
$hostname = filter_var($hostname, FILTER_VALIDATE_DOMAIN, FILTER_FLAG_HOSTNAME);
if (empty($hostname)) {
    line();
    error('Host name must be valid');
    usage();
    exit;
}

/**
 * the zip file's name without extension
 */
$distFilename = $distFilenamePrefix . kebabCase($name) . '-' . $version . $distFilenameSuffix;
line('    ' . $distFilename);

/**
 * relative path within zip file
 */
$distFilenameRootDirName = ($distFilenameRootDirName ?? true) === false ? '' : identifierCase($name);

/**
 * create replacement map
 */
$replacementMap = [
    // X.Y.Z -> 1.1.0
    'X.Y.Z' => $version,
    // "gateway.paymentgateway.cloud" -> "gateway.myprovider.com" (client xml namespace and endpoints)
    'gateway.paymentgateway.cloud' => $hostname,
    // "sandbox.paymentgateway.cloud" -> "sandbox.myprovider.com" (client xml namespace and endpoints)
    'sandbox.paymentgateway.cloud' => $hostname,
    // "github.com/ixopay/pgc-opencart" -> "github.com/user/repo" (client xml namespace and endpoints)
    'github.com/ixopay/pgc-opencart' => "github.com/user/repo",
    // "Payment Gateway Cloud" -> "My Provider"
    $placeholderName => $name,
    // "PaymentGatewayCloud" -> "MyProvider" (namespaces and other identifiers)
    pascalCase($placeholderName) => pascalCase($name),
    // "paymentGatewayCloud" -> "myProvider"
    camelCase($placeholderName) => camelCase($name),
    // "paymentgatewaycloud" -> "myprovider"
    identifierCase($placeholderName) => identifierCase($name),
    // "payment-gateway-cloud" -> "my-provider"
    kebabCase($placeholderName) => kebabCase($name),
    // "payment_gateway_cloud" -> "my_provider"
    snakeCase($placeholderName) => snakeCase($name),
    // "PAYMENT_GATEWAY_CLOUD" -> "MY_PROVIDER" (constants)
    constantCase($placeholderName) => constantCase($name),
];

/**
 * print replacement map and prompt user if planned changes are ok
 */
line();
info('Replacements for file/folder names and contents:');
foreach ($replacementMap as $old => $new) {
    line('    ' . $old . ' => ' . $new);
}
line();
prompt('This will clear any existing "' . $buildDir . '" folder and start the build. OK?');

/**
 * Prefix composer autoloader names with a unique hash.
 * This prevents conflicts in case two whitelabel plugins, which were both
 * built from the same version of the source, are installed at the same time.
 */
$composerHashPrefix = md5(identifierCase($name) . '-' . $version);
$replacementMap = array_merge($replacementMap, [
    'ComposerStaticInit' => 'ComposerStaticInit' . $composerHashPrefix,
    'ComposerAutoloaderInit' => 'ComposerAutoloaderInit' . $composerHashPrefix,
]);

/**
 * build
 * clear existing build folder
 * copy source to build folder
 * applies replacement map to folder names, file names and file contents while at it
 */
deleteDir($buildDir);
info('Building...');
build($srcDir, $buildDir, $replacementMap);
success('Build complete');

/**
 * create dist folder if needed
 */
if (!file_exists($distDir)) {
    mkdir($distDir);
    info('Created dist directory');
}

/**
 * zip build to myprovider.zip
 */
info('Creating zip file...');
zipBuildToDist($buildDir, $distDir, $distFilename, $distFilenameRootDirName);

exit;

/**
 * Helper functions below
 */

/**
 * print usage info
 */
function usage()
{
    warn('Usage: php build.php [hostname] [name]');
    line('Example: php build.php gateway.mypaymentprovider.com "My Payment Provider"');
    line();
}

/**
 * @param string $string
 * @return string
 */
function camelCase($string)
{
    return lcfirst(pascalCase($string));
}

/**
 * @param string $string
 * @return string
 */
function kebabCase($string)
{
    return str_replace('_', '-', snakeCase($string));
}

/**
 * @param string $string
 * @return string
 */
function pascalCase($string)
{
    return ucfirst(str_replace(' ', '', ucwords(strtolower(preg_replace('/^a-z0-9]+/', ' ', $string)))));
}

/**
 * @param string $string
 * @return string
 */
function snakeCase($string)
{
    return strtolower(str_replace(' ', '_', ucwords(preg_replace('/^a-z0-9]+/', ' ', $string))));
}

/**
 * @param string $string
 * @return mixed
 */
function identifierCase($string)
{
    return strtolower(pascalCase($string));
}

/**
 * @param string $string
 * @return mixed
 */
function constantCase($string)
{
    return strtoupper(snakeCase($string));
}

/**
 * @param null $message
 */
function line($message = null)
{
    echo $message . "\n";
}

/**
 * @param null $message
 */
function error($message = null)
{
    echo "\e[0;31m[ERROR] " . $message . "\e[0m\n";
}

/**
 * @param null $message
 */
function warn($message = null)
{
    echo "\e[0;33m[WARN] " . $message . "\e[0m\n";
}

/**
 * @param null $message
 */
function info($message = null)
{
    echo "\e[0;36m[INFO] " . $message . "\e[0m\n";
}

/**
 * @param null $message
 */
function success($message = null)
{
    echo "\e[0;32m[SUCCESS] " . $message . "\e[0m\n";
}

/**
 * @param string $message
 */
function highlight($message)
{
    echo "\e[0;34m" . $message . "\e[0m\n";
}

/**
 * @param string $message
 */
function debug($message)
{
    global $debug;
    if ($debug) {
        echo "\e[1;33m[DEBUG] " . $message . "\e[0m\n";
    }
}

/**
 * @param string $message
 */
function prompt($message)
{
    echo "\e[0;35m" . $message . " [y/n]\e[0m\n";
    $handle = fopen("php://stdin", "r");
    $line = fgets($handle);
    if (trim($line) !== 'y') {
        warn('Abort');
        exit;
    }
    fclose($handle);
}

/**
 * @param string $src
 * @param string $dst
 * @param array $replacementMap
 */
function build($src, $dst, $replacementMap = [])
{
    debug('Scan "' . $src . '"');

    $dir = opendir($src);
    @mkdir($dst);
    while (false !== ($file = readdir($dir))) {
        if (($file != '.') && ($file != '..')) {
            $srcFile = $src . '/' . $file;
            $destFile = $dst . '/' . applyReplacements($file, $replacementMap);
            if (is_dir($srcFile)) {
                build($srcFile, $destFile, $replacementMap);
            } else {
                debug('Copy "' . $destFile . '" -> "' . $destFile . '"');
                copy($srcFile, $destFile);
                debug('Process "' . $destFile . '"');
                replaceContents($destFile, $replacementMap);
            }
        }
    }
    closedir($dir);
}

/**
 * @param string $file
 * @param array $replacementMap
 */
function replaceContents($file, $replacementMap)
{
    file_put_contents($file, applyReplacements(file_get_contents($file), $replacementMap));
}

/**
 * @param string $string
 * @param array $replacementMap
 * @return string
 */
function applyReplacements($string, $replacementMap)
{
    foreach ($replacementMap as $old => $new) {
        $string = str_replace($old, $new, $string);
    }
    return $string;
}

/**
 * @param string $dir
 */
function deleteDir($dir)
{
    $dir = sanitizeDirInput($dir);

    $dirPath = realpath(__DIR__ . '/' . $dir);

    if (!$dirPath) {
        return;
    }

    /**
     * do not allow to delete this script's parent directory
     */
    if ($dirPath == __DIR__) {
        error('Deleting directory "' . $dir . '" is not allowed');
        exit;
    }

    /**
     * do not allow to delete any path that is not within this script's parent directory
     */
    if (strpos($dirPath, __DIR__) !== 0) {
        error('Deleting directory "' . $dir . '" is not allowed');
        exit;
    }

    warn('Deleting ' . $dirPath);

    $it = new RecursiveDirectoryIterator($dirPath, RecursiveDirectoryIterator::SKIP_DOTS);
    $files = new RecursiveIteratorIterator($it,
        RecursiveIteratorIterator::CHILD_FIRST);
    foreach ($files as $file) {
        if ($file->isDir()) {
            rmdir($file->getRealPath());
        } else {
            unlink($file->getRealPath());
        }
    }
    rmdir($dirPath);
}

/**
 * @param string $srcDir
 * @param string $destDir
 * @param string $filename
 * @param string $rootDirectoryName the root directory's name within the zip file
 */
function zipBuildToDist($srcDir, $destDir, $filename, $rootDirectoryName)
{
    $srcDir = sanitizeDirInput($srcDir);
    $destDir = sanitizeDirInput($destDir);

    $srcDirPath = realpath($srcDir);
    $destDirPath = realpath($destDir);

    $zipFilename = $filename . '.zip';

    $zip = new ZipArchive();
    $zip->open($destDirPath . '/' . $zipFilename, ZipArchive::CREATE | ZipArchive::OVERWRITE);

    /** @var SplFileInfo[] $files */
    $files = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($srcDirPath),
        RecursiveIteratorIterator::LEAVES_ONLY
    );

    foreach ($files as $name => $file) {
        /**
         * Skip directories (they would be added automatically)
         */
        if (!$file->isDir()) {
            /**
             * Get real and relative path for current file
             */
            $filePath = $file->getRealPath();
            $relativePath = substr($filePath, strlen($srcDirPath) + 1);

            $zip->addFile($filePath, $rootDirectoryName . '/' . $relativePath);
        }
    }

    /**
     * Zip archive will be created after closing object
     */
    $zip->close();

    success('Created file "' . $destDir . '/' . $zipFilename . '"');
}

/**
 * do not allow to reference a directory outside of this script's path
 *
 * @param string $dir
 * @return string
 */
function sanitizeDirInput($dir)
{
    return ltrim(str_replace('../', '', $dir), '/');
}
