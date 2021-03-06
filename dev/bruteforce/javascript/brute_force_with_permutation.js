var maxlength = 4;

var alphabet = '{$+ }#(<,.)*~];%:!^-/[&|"?0134679ABCDEFGHIJKLMNOPQRSTUVWYZabdghjknoqtuyz';
var immuable = '5e8xXmc5';

//var possibilities = Math.pow(alphabet.length, maxlength);
//console.log("nb possibilities: " + possibilities);

nbTested = 0;

var setDuplicatePermutation = new Set();

function compare(prefix){
	
	for(var i = 0; i < alphabet.length; i++){
		var pass = prefix + alphabet.charAt(i);
		var tmpPass = pass;
		
		permutation("", pass + immuable);						
		
		if(pass.length < maxlength){
			compare(pass);
		}
	}
}

function permutation(prefix,str) {
	var n = str.length;
	if (n == 0){
		
		//Traitement ici
		console.log(prefix);
		
		setDuplicatePermutation.add(prefix);
		nbTested++;
		
		if(nbTested%1000000 == 0){
			console.log("nb permutations tested: " + nbTested);
		}
	}
	else {
		for(var l = 0; l < n; l++){
			if(isValid(prefix, str.charAt(l), str.substr(0, l) + str.substr(l+1, n - (l+1)))){
				permutation(prefix + str.charAt(l), str.substr(0, l) + str.substr(l+1, n - (l+1)));
			}                   
		}
	}
}

function isValid(prefix,charPermuted,otherString){
			
	//on gère les doublons au niveau des permutations
	var fullPass = prefix + charPermuted + otherString;
	
	if(setDuplicatePermutation.has(fullPass)){
		//setDuplicatePermutation.delete(fullPass);
		return false;
	}else if(immuable.indexOf(charPermuted) != -1){
		
		for(var k = 0; k < otherString.length; k ++)
		{
			charOther = otherString.charAt(k);
			var indexOtherImmuableChar = getIndex(prefix,charOther);
			var indexCharPermuted = getIndex(prefix,charPermuted);

			if(indexOtherImmuableChar!=-1 && indexCharPermuted>indexOtherImmuableChar){
				  return false;
			}
		}
	}
	
	return true;
}

function getIndex(prefix,charForIndex){
	if(immuable.indexOf(charForIndex) != -1){
	    var re = new RegExp(charForIndex,"g");
		var nbFoisBefore= (prefix.match(re) || []).length;
		return ordinalIndexOf(immuable, charForIndex, nbFoisBefore + 1);
	}else{
		return immuable.indexOf(charForIndex);
	}
}

function ordinalIndexOf(str, charToSearch, nth){
	for (i=0;i<str.length;i++) {
		if (str.charAt(i) == charToSearch) {
			if (!--nth) {
			   return i;    
			}
		}
	}
}

//compare("");
