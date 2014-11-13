var gulp = require('gulp');
var coffee = require('gulp-coffee');
var connect = require('gulp-connect');

gulp.task('default', ['compile-coffee', 'connect', 'watch-coffee']);

gulp.task('compile-coffee', function() {
	gulp.src('./src/*.coffee')
	.pipe(coffee({bare: true}))
	.pipe(gulp.dest('./dist/'));
});

gulp.task('watch-coffee', function() {
	gulp.watch('./src/*.coffee', ['compile-coffee']);
});

gulp.task('connect', function() {
	connect.server({
		root: './'
	});
});
