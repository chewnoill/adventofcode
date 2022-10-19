# stolen from dylan 
function bin2dec(val, _result) {
  base = 1;
  while (val) {
    last_digit = substr(val, length(val), 1);
    val = substr(val, 1, length(val) - 1)
    _result += last_digit * base;
    base *= 2;
  }
  return _result;
}

{ 
    for (i = 1; i <= length($0); i++){
        if(substr($0,i,1) == 1){
            vector[i] += 1
        }else{
            vector[i] -= 1
        }
    }
}
END { 
    gamma_rate = ""
    epsilon = ""
    for (i = 1; i <= length(vector); i++){
        if(vector[i]>0){
          gamma_rate = gamma_rate "1"
          epsilon_rate = epsilon_rate "0"
        }else{
          gamma_rate = gamma_rate "0"  
          epsilon_rate = epsilon_rate "1"
        }
    }
    print "gamma_rate", bin2dec(gamma_rate)
    print "epsilon_rate", bin2dec(epsilon_rate)
    print "power", bin2dec(gamma_rate) * bin2dec(epsilon_rate)
}