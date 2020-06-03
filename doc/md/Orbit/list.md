# List module

  List collection requires paying attention to indentation, so we parse all
of the following correctly:

```orb
- List
- Same list

- New list
   
   - Same list!

   - Still same
- Same

- New

Prose break

   - New

      - Same

```

Which means we'll need to work it into the ``own`` state machine. 
