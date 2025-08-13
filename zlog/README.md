# `zlog`

## Create a new logger

Standard Output

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const writer = std.io.getStdOut().writer();

var logger = GenericLogger(std.fs.File.Writer).init(allocator, writer);
try logger.write("Hello World", .{});
```

File

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const file = try std.fs.cwd().createFile("stored_writer.log", .{});
defer file.close();
const writer = file.writer();

var logger = GenericLogger(std.fs.File.Writer).init(allocator, writer);
try logger.write("Hello World", .{});
```

Buffer

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var log_buffer = ArrayList(u8).init(allocator);
defer log_buffer.deinit();
const writer = buffer.writer();

var logger = GenericLogger(std.ArrayList(u8).Writer).init(allocator, writer);
try logger.write("Hello World", .{});
```

## `std.fs.File.Writer` vs `std.ArrayList(u8).Writer`

**What is a Buffer Logger?**

A buffer logger writes log messages to memory (an ArrayList(u8) or similar buffer) instead of directly to the terminal or file. Think of it as collecting all your log messages in a virtual notepad that you can read, process, or send somewhere later.

### Key Differences

**Stdout Logger**

- Writes to: Terminal/console immediately
- Visibility: You see messages right away
- Performance: Slower (involves system I/O calls)
- Use case: Real-time debugging, development

**Buffer Logger**

- Writes to: Memory buffer (ArrayList)
- Visibility: Messages stored until you read the buffer
- Performance: Much faster (just memory operations)
- Use case: Testing, batch processing, log analysis

### When to Use Each

**Use Stdout Logger when:**

- Development/debugging - you want to see logs immediately
- Simple applications - straightforward logging needs
- Interactive programs - real-time feedback is important
- Small volume - not logging frequently

**Use Buffer Logger when:**

- Unit testing - verify your code produces expected log messages
- Performance critical - high-frequency logging that can't slow down your app
- Log processing - need to filter, search, or modify logs before output
- Batch operations - collect logs then send them all at once to a service
- Network logging - accumulate logs then send in batches to reduce network calls
- Log analysis - programmatically examine what your application logged
