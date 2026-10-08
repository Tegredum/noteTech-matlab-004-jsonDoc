% author: Codex (GPT-5.6 Sol xhigh)
function formattedText = formatTemperature(values, unit, varargin)
	%FORMATTEMPERATURE Format numeric temperatures as a string array.
	%   TEXT = FORMATTEMPERATURE(VALUES, UNIT) formats VALUES with one digit
	%   after the decimal point and appends UNIT.
	%
	%   TEXT = FORMATTEMPERATURE(VALUES, UNIT, DIGITS) controls the number of
	%   digits after the decimal point.
	%
	%   TEXT = FORMATTEMPERATURE(___, 'Style', STYLE) selects 'fixed' (the
	%   default) or 'scientific' notation.
	%
	%   TEXT = FORMATTEMPERATURE(___, 'ShowUnit', TF) controls whether UNIT is
	%   appended. TEXT = FORMATTEMPERATURE(___, 'Prefix', PREFIX) prepends text
	%   to every formatted value.

	parser              = inputParser;
	parser.FunctionName = mfilename;

	validValues = @(x) isnumeric(x) && isreal(x) && isvector(x);
	validTextScalar = @(x)(ischar(x) && isrow(x)) || ...
		(isstring(x) && isscalar(x));
	validDigits = @(x) isnumeric(x) && isreal(x) && isscalar(x) && ...
		x == fix(x) && x >= 0 && x <= 15;
	validLogicalScalar = @(x) islogical(x) && isscalar(x);

	addRequired(parser, 'values', validValues);
	addRequired(parser, 'unit', validTextScalar);
	addOptional(parser, 'digits', 1, validDigits);
	addParameter(parser, 'Style', 'fixed', validTextScalar);
	addParameter(parser, 'ShowUnit', true, validLogicalScalar);
	addParameter(parser, 'Prefix', '', validTextScalar);
	parse(parser, values, unit, varargin{:});

	unit = validatestring(char(parser.Results.unit), ...
		{'Celsius', 'Fahrenheit', 'Kelvin'}, mfilename, 'unit');
	style = validatestring(char(parser.Results.Style), ...
		{'fixed', 'scientific'}, mfilename, 'Style');
	digits = parser.Results.digits;

	if strcmp(style, 'fixed')
		formatSpec = sprintf('%%.%df', digits);
	else
		formatSpec = sprintf('%%.%de', digits);
	end

	formattedText = string(compose(formatSpec, values));
	if parser.Results.ShowUnit
		formattedText = formattedText + " " + string(unit);
	end
	if ~isempty(parser.Results.Prefix)
		formattedText = string(parser.Results.Prefix) + formattedText;
	end
end
