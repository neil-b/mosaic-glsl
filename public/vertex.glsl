/* Vertex shader */
precision highp float;
precision highp int;

void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

