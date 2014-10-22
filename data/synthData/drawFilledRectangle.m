function drawFilledRectangle( left, right, bottom, top, color )
    x = [left left right right];
    y = [bottom top top bottom];
    fill(x, y, color);
end