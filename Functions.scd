var returnDict = ();
//Sorting low and high buffers, outputing an array with longest first 
var sortArrayByDuration = {
    arg array, longest_first = true;
    var sorted_hi = List();

    array.do({
        arg buf, i; 
        if(sorted_hi.size == 0, {sorted_hi.add(buf);},
        {
            var inserted = false, index = 0;
            while({inserted == false})
            {
                if(buf.duration<sorted_hi[index].duration)
                {
                    sorted_hi = sorted_hi.insert(index,buf); 
                    inserted = true;
                }; 
                index = index + 1;
                if(index == sorted_hi.size)
                {
                    sorted_hi.add(buf);
                    inserted = true;
                };
            }
        });
    });

    if(longest_first)
    {
        array = sorted_hi.reverse;//longest first
    };
    array;
};

returnDict.add(\sortArrayByDuration -> sortArrayByDuration);
returnDict;
