<?php

use PhpParser\Error;
use PhpParser\NodeDumper;
use PhpParser\ParserFactory;

use Illuminate\Support\Facades\Log;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use Illuminate\Support\Str;
use Illuminate\View\Factory;
use Illuminate\View\FileViewFinder;
use Illuminate\Filesystem\Filesystem;
use Illuminate\View\Engines\CompilerEngine;
use Illuminate\View\Compilers\BladeCompiler;

config(['logging.default' => 'errorlog']);

Route::get('/csrf_token', function() { return csrf_token(); });

Route::post('/to/php/ast', function (Request $request) {

    $file = $request->file('source');
    if (!$file) { return "ERROR"; }

    $code = file_get_contents($file);
    $parser = (new ParserFactory())->createForNewestSupportedVersion();

    try { $ast = $parser->parse($code); }
    catch (Error $error) { return "ERROR"; }

    $dumper = new NodeDumper(['dumpPositions' => true]);
    return $dumper->dump($ast, $code) . "\n";
});

Route::post('/to/php/code', function (Request $request) {
    $file = $request->file('source');
    if (!$file) {
        return response('ERROR: No file uploaded', 400);
    }

    $content = file_get_contents($file);

    // ⚠️ Strip problematic Blade directives (optional but useful)
    $content = preg_replace('/@include\((.*?)\)/', '', $content);
    $content = preg_replace('/@extends\((.*?)\)/', '', $content);
    $content = preg_replace('/@section(.*?)@endsection/s', '', $content);

    // Blade compiler needs an available directory
    // for writing temporary files
    $filesystem = new Filesystem();
    $tempDir = sys_get_temp_dir();

    // Compile with BladeCompiler
    $compiler = new BladeCompiler($filesystem, $tempDir);

    try { $compiled = $compiler->compileString($content); }
    catch (\Throwable $e) { return response("ERROR: " . $e->getMessage(), 400); }

    // now extract actual php code from relevant tags
    preg_match_all('/<\?php\s+(.*?)\s*\?>/s', $compiled, $matches);
    $statements = array_filter($matches[1]);
    $code = implode(";\n", $statements) . ";\n";

    // for some debug options
    $originalName = $file->getClientOriginalName();
    $end = 'link-display.blade.php';
    if (str_ends_with($originalName, $end)) {
        $message = sprintf("Received file: %s", $originalName);
        Log::info($message);        
        $message = sprintf("Received content: %s", $content);
        Log::info($message);        
        $message = sprintf("Proper php code: %s", $code);
        Log::info($message);        
    }

    return response("<?php\n" . $code)->header('Content-Type', 'text/plain');
});
