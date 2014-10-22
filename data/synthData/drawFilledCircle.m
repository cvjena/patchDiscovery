function drawFilledCircle( xc, yc, radius, color )
    x = radius*sin(-pi:0.1*pi:pi) + xc;
    y = radius*cos(-pi:0.1*pi:pi) + yc;
    fill(x, y, color, 'FaceAlpha', 1);
end