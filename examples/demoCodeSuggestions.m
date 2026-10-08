%% JSON code-suggestion example
% author: Codex (GPT-5.6 Sol xhigh)
% Run this file to exercise formatTemperature. To inspect completions, open
% this file in the desktop Editor or Live Editor, start a new call such as
% `formatTemperature(`, and press Tab while entering arguments.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);

fixedText = formatTemperature([0, 23.45, 100], 'Celsius', 1);
scientificText = formatTemperature(273.15, 'Kelvin', 3, ...
	'Style', 'scientific', 'Prefix', 'T = ');
withoutUnit = formatTemperature([-40, 32], 'Fahrenheit', ...
	'ShowUnit', false);

disp(fixedText);
disp(scientificText);
disp(withoutUnit);
