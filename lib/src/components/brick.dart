import 'dart:math';
import 'dart:ui';
import 'package:brick_breaker/src/config.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../brick_breaker.dart';
import 'ball.dart';


class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  int lifespan;
  final bool isBreakable;
  final double moveSpeed = 150.0; // Speed at which bricks move
  late Vector2 initialPosition;
  late bool movingRight; // Direction flag for left/right movement
  late double screenWidth; // To keep track of the screen width
  bool shouldMove = false; // Flag to control brick movement

  Brick({
    required super.position,
    required Color color,
    required this.isBreakable,
    this.lifespan = 0,
    required BrickBreaker game,
  }) : super(
          size: Vector2(brickWidth, brickHeight),
          anchor: Anchor.center,
          paint: Paint()
            ..color = _getComplementaryColor(color)
            ..style = PaintingStyle.fill,
          children: [RectangleHitbox()],
        ) {
    initialPosition = position.clone();
    game.score.addListener(_checkAndStartMovement);
    movingRight = true;
    screenWidth = game.size.x;
  }

  static Color _getComplementaryColor(Color baseColor) {
    return Color.fromARGB(
      baseColor.alpha,
      255 - baseColor.red,
      255 - baseColor.green,
      255 - baseColor.blue,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (shouldMove) {
      _moveLeftRight(dt);
    }
  }

  void _moveLeftRight(double dt) {
    if (movingRight) {
      position.x += moveSpeed * dt;
    } else {
      position.x -= moveSpeed * dt;
    }

    // Reverse direction when hitting the edge
    if (position.x >= screenWidth - size.x / 2 || position.x <= size.x / 2) {
      movingRight = !movingRight;
    }
  }

  void _checkAndStartMovement() {
    // When score reaches 2, bricks start moving
    if (game.score.value == 2) {
      shouldMove = true;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Handle collision only for breakable bricks when hit by a ball
    if (isBreakable && other is Ball) {
      lifespan--; // Decrease lifespan

      if (lifespan <= 0) {
        removeFromParent(); // Remove brick
        game.score.value += 1; // Increment score
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPainter = TextPainter(
      text: TextSpan(
        text: isBreakable ? lifespan.toString() : "",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.x / 2 - textPainter.width / 2,
        size.y / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  void onRemove() {
    super.onRemove();
    game.score.removeListener(_checkAndStartMovement);
  }
}

// Method to generate random unbreakable bricks
void generateRandomUnbreakableBricks(BrickBreaker game) {
  final Random random = Random();
  for (int i = 0; i < 10; i++) {
    final double x = random.nextDouble() * (game.size.x - brickWidth);
    final double y = random.nextDouble() * (game.size.y / 3); // Top third of the screen

    final brick = Brick(
      position: Vector2(x, y),
      color: Colors.grey,
      isBreakable: false,
      game: game,
    );
    game.add(brick);
  }
}

// Method to generate initial breakable bricks
void generateInitialBreakableBricks(BrickBreaker game) {
  final int rows = 4;
  final int columns = 6;
  final double spacing = 10.0;

  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < columns; col++) {
      final double x = col * (brickWidth + spacing) + spacing;
      final double y = row * (brickHeight + spacing) + spacing;

      final brick = Brick(
        position: Vector2(x, y),
        color: Colors.blue,
        isBreakable: true,
        lifespan: 3, // Initial lifespan for breakable bricks
        game: game,
      );
      game.add(brick);
    }
  }
}
