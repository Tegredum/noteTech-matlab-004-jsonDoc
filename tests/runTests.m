function runTests
	%RUNTESTS Verify the example function and its function-signature metadata.
	% author: Codex (GPT-5.6 Sol xhigh, GPT-6.1 Sol max)

	projectRoot = fileparts(fileparts(mfilename('fullpath')));
	addpath(projectRoot);
	removePath = onCleanup(@() rmpath(projectRoot));

	actual = formatTemperature([0, 100], 'Celsius');
	assert(isequal(actual, ["0.0 Celsius", "100.0 Celsius"]));

	actual = formatTemperature(273.15, "Kelvin", 2, ...
		'Style', 'scientific', 'Prefix', 'T=', 'ShowUnit', false);
	assert(isequal(actual, "T=2.73e+02"));

	actual = formatTemperature([-40, 32], 'Fahrenheit', 'ShowUnit', false);
	assert(isstring(actual));
	assert(isequal(actual, ["-40.0", "32.0"]));

	% A single choices list must not narrow runtime text-type support.
	units  = {'Celsius', 'Fahrenheit', 'Kelvin'};
	styles = {'fixed', 'scientific'};
	for unitIndex = 1:numel(units)
		for styleIndex = 1:numel(styles)
			charResult = formatTemperature(12.5, units{unitIndex}, 2, ...
				'Style', styles{styleIndex});
			stringResult = formatTemperature(12.5, string(units{unitIndex}), 2, ...
				'Style', string(styles{styleIndex}));
			assert(isequal(charResult, stringResult), ...
				'Character vectors and string scalars should behave identically.');
		end
	end

	didRejectInvalidUnit = false;
	try
		formatTemperature(1, 'Rankine');
	catch
		didRejectInvalidUnit = true;
	end
	assert(didRejectInvalidUnit, 'An unsupported unit should be rejected.');

	signatureFile = fullfile(projectRoot, 'resources', ...
		'functionSignatures.json');
	signatureData = jsondecode(fileread(signatureFile));
	assert(strcmp(signatureData.x_schemaVersion, '1.0.0'));
	assert(isfield(signatureData, 'formatTemperature'));

	validationMessages = validateFunctionSignaturesJSON(signatureFile);
	assert(isempty(validationMessages), ...
		'functionSignatures.json did not pass MATLAB schema validation.');

	fprintf('All function and JSON signature tests passed.\n');
end
