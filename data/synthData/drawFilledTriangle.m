function drawFilledTriangle( left, bottom, width, color )
    x = [left, left+width, round(left+0.5*width)];
    y = [bottom, bottom, bottom-round(sqrt(3)/2*width)];
    fill(x, y, color);
end