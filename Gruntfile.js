module.exports = function(grunt) {
    "use strict";

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        mochaTest: {
            test: {
                options: {
                    reporter: 'spec'
                },
                src: [
                    "test/**/*.js"
                ]
            }
        },
        jshint: {
            src: [
                // Files to hint
                "Gruntfile.js",
                "test/**/*.js",
            ],
            options: {
                jshintrc: '.jshintrc'
            },
        }
    });

    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-mocha-test');

    grunt.registerTask('test', ['jshint', 'mochaTest']);
    grunt.registerTask('default', ['test']);
};