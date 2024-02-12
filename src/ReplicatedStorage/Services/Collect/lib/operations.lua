return {
	["="]  = function(x,y) return x == y end;
	["=="] = function(x,y) return x == y end;
	["~="] = function(x,y) return x ~= y end;
	["!="] = function(x,y) return x ~= y end;
	["<>"] = function(x,y) return x ~= y end;
	[">="] = function(x,y) return x >= y end;
	["<="] = function(x,y) return x <= y end;
	[">"]  = function(x,y) return x >  y end;
	["<"]  = function(x,y) return x <  y end;
}