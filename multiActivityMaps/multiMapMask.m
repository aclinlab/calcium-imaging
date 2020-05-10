function mask = multiMapMask()

params = activityMapParams;
params.preLimits = [10 15];
params.stimLimits = [20 25];

map = activityMap(params);

mask = logical(map.outlineObject(1));

end