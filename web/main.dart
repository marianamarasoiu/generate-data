import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

/// Here we save the points that are being generated.
List<List<int>> points = [];

math.Random randomGenerator = new math.Random();
int variance = 100; // in pixels
int pointSize = 2; // in pixels

void main() {
  drawPointsOnMouseMove();
  
  // Listen to changes to the variance input form.
  TextInputElement varianceElement = querySelector('#variance');
  varianceElement.value = variance.toString();
  varianceElement.onChange.listen((Event e) {
    try {
      variance = int.parse(varianceElement.value);
    } catch (error) {
      window.alert('The value entered for the variance (${varianceElement.value}) is not an interger!');
    }
  });

  // Listen to changes to the size of the dots in the visualisation.
  TextInputElement pointSizeElement = querySelector('#point-size');
  pointSizeElement.value = pointSize.toString();
  pointSizeElement.onChange.listen((Event e) {
    try {
      pointSize = int.parse(pointSizeElement.value);
    } catch (error) {
      window.alert('The value entered for the point size (${pointSizeElement.value}) is not an interger!');
    }
  });

  // Setup clear button
  ButtonElement clearButton = querySelector('#clear-data');
  clearButton.onClick.listen((MouseEvent mouseClickEvent) {
    points.clear();
    // Draw a large white rectangle over the canvas.
    CanvasElement canvas = querySelector('#canvas');
    CanvasRenderingContext2D context = canvas.getContext('2d');
    context.fillStyle = '#ffffff'; // set the color to white.
    context.fillRect(0, 0, 1000, 800); // these need to match the height and width of the canvas in the html file.
    context.fillStyle = '#000000'; // go back to drawing with black.
  });

  // Setup download button
  ButtonElement downloadButton = querySelector('#download-data');
  downloadButton.onClick.listen((MouseEvent mouseClickEvent) {
    String csvFileContent = listToCsv(points);
    String encodedData = Uri.encodeComponent(csvFileContent);

    new AnchorElement(href: 'data:text/plain; charset=utf-8, $encodedData')
      ..setAttribute("download", "data.csv")
      ..click();
  });
}

void drawPointsOnMouseMove() {
  CanvasElement canvas = querySelector('#canvas');
  CanvasRenderingContext2D context = canvas.getContext('2d');

  Rectangle canvasRectangle = canvas.getBoundingClientRect(); // we need this to get the position of the canvas on the page
  int canvasX = canvasRectangle.left; // the top left corner of the canvas
  int canvasY = canvasRectangle.top; // the top left corner of the canvas
  int canvasHeight = canvasRectangle.height;
  canvas.onMouseDown.listen((MouseEvent mouseDown) {
    // find the x and y of the mouse relative to the canvas.
    // mouseDown.client.x and canvasX are both relative to the top left corner of the entire page
    int x = mouseDown.client.x - canvasX;
    int y = mouseDown.client.y - canvasY;

    x = generateNormalDistributedValueAroundMean(x, variance).abs(); // use absolute values (abs()) to not have points outside the borders of the canvas
    y = generateNormalDistributedValueAroundMean(y, variance).abs();
    points.add([x, canvasHeight - y]);

    context.fillRect(x, y, pointSize, pointSize);
    
    StreamSubscription mouseMoveListener = canvas.onMouseMove.listen((MouseEvent mouseMove) {
      int x = mouseMove.client.x - canvasX;
      int y = mouseMove.client.y - canvasY;

      x = generateNormalDistributedValueAroundMean(x, variance).abs();
      y = generateNormalDistributedValueAroundMean(y, variance).abs();
      points.add([x, canvasHeight - y]);
      context.fillRect(x, y, pointSize, pointSize);
    });

    canvas.onMouseUp.first.then((MouseEvent mouseUp) {
      int x = mouseUp.client.x - canvasX;
      int y = mouseUp.client.y - canvasY;
      
      x = generateNormalDistributedValueAroundMean(x, variance).abs();
      y = generateNormalDistributedValueAroundMean(y, variance).abs();
      points.add([x, canvasHeight - y]);
      context.fillRect(x, y, pointSize, pointSize);
      mouseMoveListener.cancel();
    });
  });
}

/// The default random generator in Dart uses a uniform distribution.
/// Sdd multiple of them up to create a normal distribution.
generateNormalDistributedValueAroundMean(int mean, int variance) {
  double sumOfUniformRandom =
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble() +
    randomGenerator.nextDouble();
  double normalDistributedRandom = sumOfUniformRandom / 8; // we have added 8 doubles - normalise back to [0-1)
  return mean + ((normalDistributedRandom - 0.5) * 2 * variance).toInt();
}

/// Transform a list object to a string in CSV format
String listToCsv(List<List<int>> listData) {
  listData.sort((List<int> a, List<int> b) {
    return a[0].compareTo(b[0]);
  });
  StringBuffer csvData = new StringBuffer(); // We use string buffers to concatenate multiple strings quicker
  listData.forEach((List<int> row) {
    StringBuffer csvDataRow = new StringBuffer();
    row.forEach((int cell) => csvDataRow.write('$cell, '));
    String csvDataRowString = csvDataRow.toString();
    // the string representing the row now ends with ", ". remove it
    csvDataRowString = csvDataRowString.substring(0, csvDataRowString.length - 2);
    csvData.writeln(csvDataRowString);
  });
  return csvData.toString();
}
