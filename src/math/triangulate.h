#pragma once

#include <glm/vec2.hpp>
#include <vector>

class Triangulate
{
public:
    typedef std::vector<glm::vec2> Path;
    typedef std::vector<uint16_t> Indices;

    static bool process(const Path& input, Indices& output)
    {
        int n = input.size();
        if (n < 3) return false;

        int* indexes = new int[n];

        if (area(input) > 0.0f)
            for (int v = 0; v < n; v++) indexes[v] = v;
        else
            for (int v = 0; v < n; v++) indexes[v] = (n - 1) - v;

        int nv = n;
        // Remove nv-2 bertices, creating 1 triangle every time.
        int count = 2 * nv; // Error detection
        for (int v = nv - 1; nv > 2; )
        {
            // If we loop, it is probably a non-simple polygon.
            if (count-- < 0)
            {
                // Triangulate: ERROR - probable bad polygon!
                delete[] indexes;
                return false;
            }

            // Three consecutive vertices in current polygon, <u, v, w>
            int u = v  ; if (nv <= u) u = 0; // previou
            v = u+1; if (nv <= v) v = 0;     // new v
            int w = v+1; if (nv <= w) w = 0; // next

            if (snip(input, u, v, w, nv, indexes))
            {
                int a, b, c, s, t;

                // True names of the vertices
                a = indexes[u]; b = indexes[v]; c = indexes[w];

                // Output triangle
                output.push_back(a);
                output.push_back(b);
                output.push_back(c);

                // Remove v from remaining polygon
                for (s = v, t = v + 1; t < nv; s++, t++)
                    indexes[s] = indexes[t];
                nv--;
                // Reset error detection counter
                count = 2 * nv;
            }
        }

        delete[] indexes;
        return true;
    }
private:
    static float area(const Path &input)
    {
        float result = 0;
        int p0 = input.size() - 1;

        for (unsigned int p1 = 0; p1 < input.size(); p1++)
        {
            result += input[p0].x * input[p1].y - input[p1].x * input[p0].y;
            p0 = p1;
        }

        return result * 0.5f;
    }

    static bool inside(glm::vec2 a, glm::vec2 b, glm::vec2 c, glm::vec2 p)
    {
        const glm::vec2 cb = c - b;
        const glm::vec2 ac = a - c;
        const glm::vec2 ba = b - a;

        const glm::vec2 pa = p - a;
        const glm::vec2 pb = p - b;
        const glm::vec2 pc = p - c;

        const float cross_a = ba.x * pa.y - ba.y * pa.x;
        const float cross_b = cb.x * pb.y - cb.y * pb.x;
        const float cross_c = ac.x * pc.y - ac.y * pc.x;

        return cross_a >= 0.0f && cross_b >= 0.0f && cross_c >= 0.0f;
    }

    static bool snip(const Path &input, int u, int v, int w, int n, int* indexes)
    {
        glm::vec2 a = input[indexes[u]];
        glm::vec2 b = input[indexes[v]];
        glm::vec2 c = input[indexes[w]];

        if (0.0000000001f > (((b.x - a.x) * (c.y - a.y)) - ((b.y - a.y) * (c.x - a.x))) )
            return false;

        for (int index = 0; index < n; index++)
        {
            if ((index == u) || (index == v) || (index == w)) continue;

            glm::vec2 p = input[indexes[index]];

            if (inside(a, b, c, p)) return false;
        }

        return true;
    }
};
