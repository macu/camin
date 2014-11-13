
var ptRadius = 10;
var warper = new Warper();

$(function() {

	var isDrawing = false;
	var isMovingAnchor = false;
	var lines = [];
	var currentLine = [];
	var cursor = [0,0];

	var $input = $("canvas#input");
	var inputWidth = +$input.attr('width'), inputHeight = +$input.attr('height');
	var inputCanvas = $input[0];
	var inputContext = inputCanvas.getContext('2d');

	var pts = [[0, 0], [inputWidth, 0], [0.1, inputHeight], [inputWidth, inputHeight]];
	warper.setSource(pts[0][0], pts[0][1], pts[1][0], pts[1][1], pts[2][0], pts[2][1], pts[3][0], pts[3][1]);
	warper.setDestination(pts[0][0], pts[0][1], pts[1][0], pts[1][1], pts[2][0], pts[2][1], pts[3][0], pts[3][1]);

	var $output = $("canvas#output");
	var outputWidth = $output.attr('width'), outputHeight = $output.attr('height');
	var outputCanvas = $output[0];
	var outputContext = outputCanvas.getContext('2d');

	$input.on("mousedown", function(e) {
		cursor = getMousePosition($(this), e);
		for (var i = 0; i < pts.length; i++) {
			if (inCircle(pts[i], ptRadius, cursor)) {
				isMovingAnchor = i;
				return;
			}
		}
		isDrawing = true;
		currentLine = [];
		lines.push(currentLine);
		currentLine.push(cursor);
	});

	$input.on("mousemove", function(e) {
		cursor = getMousePosition($(this), e);
		if (isMovingAnchor !== false) {
			pts[isMovingAnchor] = cursor;
			warper.setSource(pts[0][0], pts[0][1], pts[1][0], pts[1][1], pts[2][0], pts[2][1], pts[3][0], pts[3][1]);
		} else if (isDrawing) {
			currentLine.push(getMousePosition($(this), e));
		}
	});

	$input.on("mouseup mouseleave", function(e) {
		if (isMovingAnchor !== false) {
			isMovingAnchor = false;
		} else if (isDrawing) {
			isDrawing = false;
			currentLine.push(getMousePosition($(this), e));
		}
	});

	Animator.start(function() {
		inputContext.clearRect(0, 0, inputWidth, inputHeight);
		drawLines(inputContext, lines);
		drawQuadAndCircles(inputContext, pts[0], pts[1], pts[2], pts[3]);
		return true;
	}, null, inputCanvas);

	Animator.start(function() {
		outputContext.clearRect(0, 0, inputWidth, inputHeight);
		drawLines(outputContext, lines, warper);
		drawCircle(outputContext, cursor, 4);
		return true;
	}, null, outputCanvas);

});

function drawLines(context, lines, warper) {
	for (var li = 0; li < lines.length; li++) {
		var line = lines[li];
		context.beginPath();
		for (var pi = 0; pi < line.length; pi++) {
			var p = line[pi];
			if (warper) {
				p = warper.warp(p[0], p[1]);
			}
			if (pi === 0) {
				context.moveTo(p[0], p[1]);
			} else {
				context.lineTo(p[0], p[1]);
			}
		}
		context.stroke();
	}
}

function drawCircle(context, pt, r) {
	context.beginPath();
	context.arc(pt[0], pt[1], r, 0, 2 * Math.PI);
	context.stroke();
}

function drawQuadAndCircles(context, ptA, ptB, ptC, ptD) {
	context.beginPath();
	context.moveTo(ptA[0], ptA[1]);
	context.lineTo(ptB[0], ptB[1]);
	context.lineTo(ptD[0], ptD[1]);
	context.lineTo(ptC[0], ptC[1]);
	context.closePath();
	context.stroke();
	drawCircle(context, ptA, ptRadius);
	drawCircle(context, ptB, ptRadius);
	drawCircle(context, ptC, ptRadius);
	drawCircle(context, ptD, ptRadius);
}

function inCircle(ptCenter, r, pt) {
	var xd = ptCenter[0] - pt[0], yd = ptCenter[1] - pt[1];
	return ((xd * xd) + (yd * yd)) <= (r * r);
}

function getMousePosition($element, event) {
	var offset = $element.offset();
	return [event.pageX - offset.left, event.pageY - offset.top];
}
