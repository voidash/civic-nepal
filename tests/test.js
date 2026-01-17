#!/usr/bin/env node

/**
 * Test suite for Constitution Web App
 * Run with: node tests/test.js
 */

const fs = require('fs');
const path = require('path');

const ANSI = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    cyan: '\x1b[36m',
    bold: '\x1b[1m'
};

let passed = 0;
let failed = 0;
let skipped = 0;

function assert(condition, message) {
    if (condition) {
        console.log(`${ANSI.green}✓ PASS${ANSI.reset} ${message}`);
        passed++;
    } else {
        console.log(`${ANSI.red}✗ FAIL${ANSI.reset} ${message}`);
        failed++;
    }
}

function skip(message) {
    console.log(`${ANSI.yellow}○ SKIP${ANSI.reset} ${message}`);
    skipped++;
}

function section(name) {
    console.log(`\n${ANSI.cyan}${ANSI.bold}=== ${name} ===${ANSI.reset}`);
}

// Load and parse index.html
const indexPath = path.join(__dirname, '..', 'index.html');
let indexContent = '';
try {
    indexContent = fs.readFileSync(indexPath, 'utf-8');
} catch (e) {
    console.error(`${ANSI.red}ERROR: Cannot read index.html: ${e.message}${ANSI.reset}`);
    process.exit(1);
}

// Load JSON data files
const dataPath = path.join(__dirname, '..');
let constitutionData = null;
let perSentenceData = null;
let dictionaryData = null;
let districtsData = null;

try {
    constitutionData = JSON.parse(fs.readFileSync(path.join(dataPath, 'constitution_bilingual.json'), 'utf-8'));
} catch (e) {
    console.error(`${ANSI.red}ERROR: Cannot load constitution_bilingual.json: ${e.message}${ANSI.reset}`);
}

try {
    perSentenceData = JSON.parse(fs.readFileSync(path.join(dataPath, 'per-sentence.json'), 'utf-8'));
} catch (e) {
    console.error(`${ANSI.red}ERROR: Cannot load per-sentence.json: ${e.message}${ANSI.reset}`);
}

try {
    dictionaryData = JSON.parse(fs.readFileSync(path.join(dataPath, 'dictionary.json'), 'utf-8'));
} catch (e) {
    console.error(`${ANSI.red}ERROR: Cannot load dictionary.json: ${e.message}${ANSI.reset}`);
}

try {
    districtsData = JSON.parse(fs.readFileSync(path.join(dataPath, 'districts.json'), 'utf-8'));
} catch (e) {
    console.error(`${ANSI.red}ERROR: Cannot load districts.json: ${e.message}${ANSI.reset}`);
}

// Run tests
console.log(`${ANSI.bold}Constitution Web App Test Suite${ANSI.reset}`);
console.log(`Testing: ${indexPath}`);

section('Data Files');

if (constitutionData) {
    // Data is wrapped in "constitution" key
    const constitution = constitutionData.constitution || constitutionData;
    assert(constitution.parts && constitution.parts.length > 0,
        'constitution_bilingual.json has parts array');
    assert(constitution.parts[0].articles,
        'Constitution parts have articles property');
    assert(constitution.parts.length >= 30,
        `Constitution has at least 30 parts (found: ${constitution.parts.length})`);

    let articleCount = 0;
    constitution.parts.forEach(p => {
        if (p.articles) articleCount += p.articles.length;
    });
    assert(articleCount >= 300,
        `Constitution has at least 300 articles (found: ${articleCount})`);
} else {
    skip('Cannot test constitution data - file not loaded');
}

if (perSentenceData) {
    // Data is wrapped in "constitution" key
    const ps = perSentenceData.constitution || perSentenceData;
    assert(ps.preamble && ps.preamble.aligned_sentences,
        'per-sentence.json has preamble with aligned_sentences');
    assert(Array.isArray(ps.preamble.aligned_sentences),
        'aligned_sentences is an array');
    assert(ps.preamble.aligned_sentences.length > 0,
        'preamble has at least one aligned sentence');
} else {
    skip('Cannot test per-sentence data - file not loaded');
}

if (dictionaryData) {
    assert(dictionaryData.np_to_en || dictionaryData.en_to_np,
        'dictionary.json has np_to_en or en_to_np mappings');
    if (dictionaryData.np_to_en) {
        assert(typeof dictionaryData.np_to_en === 'object',
            'np_to_en is an object');
        assert(Object.keys(dictionaryData.np_to_en).length > 1000,
            `Dictionary has substantial entries (found: ${Object.keys(dictionaryData.np_to_en).length})`);
    }
} else {
    skip('Cannot test dictionary data - file not loaded');
}

if (districtsData) {
    assert(typeof districtsData === 'object',
        'districts.json is an object');
    assert(Object.keys(districtsData).length >= 70,
        `Has at least 70 districts (found: ${Object.keys(districtsData).length})`);
} else {
    skip('Cannot test districts data - file not loaded');
}

section('HTML Structure');

assert(indexContent.includes('<!DOCTYPE html>'),
    'Has valid DOCTYPE declaration');
assert(indexContent.includes('<meta charset="UTF-8">'),
    'Has UTF-8 charset meta tag');
assert(indexContent.includes('viewport'),
    'Has responsive viewport meta tag');
assert(indexContent.includes('<title>'),
    'Has title tag');

section('CSS Features');

assert(indexContent.includes('.layout') || indexContent.includes('display: grid'),
    'Has CSS grid layout');
assert(indexContent.includes('@media'),
    'Has responsive media queries');
assert(indexContent.includes('@media print'),
    'Has print stylesheet');
assert(indexContent.includes('.sidebar-left') || indexContent.includes('.main-content'),
    'Has sidebar/main content structure');

section('JavaScript Features');

assert(indexContent.includes('function ') || indexContent.includes('const ') || indexContent.includes('let '),
    'Has JavaScript code');

// Check for critical functions
const criticalFunctions = [
    [/function\s+renderTOC|const\s+renderTOC/, 'renderTOC function'],
    [/function\s+renderParagraphView|const\s+renderParagraphView/, 'renderParagraphView function'],
    [/function\s+renderSentenceView|const\s+renderSentenceView/, 'renderSentenceView function'],
    [/function\s+linkifyArticleRefs|const\s+linkifyArticleRefs/, 'linkifyArticleRefs function'],
    [/function\s+navigateFromHash|const\s+navigateFromHash/, 'navigateFromHash function'],
    [/function\s+devanagariToArabic|const\s+devanagariToArabic/, 'devanagariToArabic function'],
];

criticalFunctions.forEach(([pattern, name]) => {
    if (pattern.test(indexContent)) {
        assert(true, `Has ${name}`);
    } else {
        assert(false, `Missing ${name}`);
    }
});

section('Interactive Features');

// Language toggle
assert(indexContent.includes('lang-toggle') || indexContent.includes('currentLang'),
    'Has language toggle UI/state');

// View mode toggle
assert(indexContent.includes('view-toggle') || indexContent.includes('currentView') || indexContent.includes('paragraphView') || indexContent.includes('sentenceView'),
    'Has view mode toggle UI/state');

// Meaning mode
assert(indexContent.includes('meaningMode') || indexContent.includes('meaning-mode') || indexContent.includes('showTooltip'),
    'Has meaning mode functionality');

// Search
assert(indexContent.includes('searchBox') || indexContent.includes('.search') || /search.*addEventListener/i.test(indexContent),
    'Has search functionality');

// Deep linking
assert(indexContent.includes('#article-') || indexContent.includes('#preamble') || indexContent.includes('navigateFromHash'),
    'Has deep linking via hash');

section('Security Checks');

// Check for potential XSS vulnerabilities with innerHTML and user/dictionary data
const lines = indexContent.split('\n');
let potentialXSS = false;
lines.forEach((line, idx) => {
    // Check if innerHTML is used with potentially unsafe data
    if (/innerHTML\s*=.*\b(dictionary|user|translation|query|search)/i.test(line)) {
        console.log(`${ANSI.red}⚠ Line ${idx + 1}: ${line.trim()}${ANSI.reset}`);
        potentialXSS = true;
    }
});
assert(!potentialXSS,
    'No obvious XSS vulnerabilities (innerHTML with dictionary/user data)');

section('Event Initialization');

// Check that event listeners are initialized AFTER data loads
// This is a common bug - events attached before data exists
const initEventPattern = /initEventListeners\s*\(\)|addEventListener\s*\(/g;
const matches = indexContent.match(initEventPattern) || [];
assert(matches.length > 0,
    `Has event listener initialization (${matches.length} occurrences)`);

// Check for proper sequencing (fetch -> render -> events)
// Look for Promise.all with fetch followed by render() call
const hasProperSequencing = /Promise\.all\([^)]*fetch[^)]*\)\s*\.then\([^)]*render\s*\(\)/.test(indexContent) ||
                          /fetch\s*\([^)]*\)\s*\.then\([^)]*render/.test(indexContent) ||
                          /initEventListeners\s*\(\).*render|render.*initEventListeners/s.test(indexContent);
assert(hasProperSequencing,
    'Has data fetch before render (proper sequencing)');

section('Accessibility');

assert(indexContent.includes('aria-') || indexContent.includes('role=') || indexContent.includes('<nav') || indexContent.includes('<main'),
    'Has some accessibility attributes (aria, role, nav, main)');
assert(indexContent.includes('<button') || indexContent.includes('type="button"'),
    'Uses button elements for interactivity');

section('Summary');

console.log(`\n${ANSI.bold}Test Results:${ANSI.reset}`);
console.log(`${ANSI.green}Passed: ${passed}${ANSI.reset}`);
console.log(`${ANSI.red}Failed: ${failed}${ANSI.reset}`);
console.log(`${ANSI.yellow}Skipped: ${skipped}${ANSI.reset}`);
console.log(`Total: ${passed + failed + skipped}`);

const exitCode = failed > 0 ? 1 : 0;
process.exit(exitCode);
