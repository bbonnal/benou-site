+++
title = "Template presentation"
outputs = ["Reveal"]
[reveal_hugo]
custom_theme = "benou-theme.scss"
custom_theme_compile = true
[logo]
src = "/slides/img/logo_w.svg"
+++

## Template Example

---

This presentation shows how to take advantage of reveal-hugo's slide template feature.

---




---

## Hello

Here's an example of using a template called `blue`, defined in the front matter of this presentation's `_index.md` file.

---

The template can contain any valid slide customization params:

using System; 

```csharp
namespace HelloWorldApp { 
    
    class Geeks { 
        
        static void Main(string[] args) { 
            
            // statement printing Hello World! 
            Console.WriteLine("Hello World!"); 
            
            // To prevent the screen from running and closing quickly 
            Console.ReadKey(); 
        } 
    } 
}
```

---

Then add it to any slide using the slide shortcode:

```
{{</* slide template="blue" */>}}
```

