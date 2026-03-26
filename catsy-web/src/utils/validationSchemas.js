import { z } from 'zod';

/**
 * Zod Schemas for Catsy Coffee Admin Forms
 * Provides runtime type checking and data sanitization.
 */

// 1. Product Schema
export const productSchema = z.object({
    product_name: z.string()
        .min(2, "Product name must be at least 2 characters")
        .max(100, "Product name is too long")
        .trim(),
    product_price: z.number()
        .positive("Price must be a positive number")
        .min(0.01, "Price must be at least 0.01"),
    category_id: z.number({ required_error: "Category is required" }),
    product_is_available: z.boolean().default(true),
    product_is_featured: z.boolean().default(false),
    product_is_eligible: z.boolean().default(true),
    product_is_reward: z.boolean().default(false),
});

// 2. Category / Reward Schema
export const categorySchema = z.object({
    name: z.string()
        .min(2, "Name must be at least 2 characters")
        .max(100, "Name is too long")
        .trim(),
    description: z.string().max(500, "Description is too long").optional().nullable(),
    linked_product_id: z.number().optional().nullable(),
});

// 3. Material Schema
export const materialSchema = z.object({
    material_name: z.string()
        .min(2, "Material name must be at least 2 characters")
        .max(100, "Material name is too long")
        .trim(),
    material_unit: z.enum(['grams', 'ml', 'pcs', 'kg', 'liters', 'oz', 'tbsp', 'tsp'], {
        required_error: "Unit is required"
    }),
    cost_per_unit: z.number().min(0).optional().nullable(),
    material_stock: z.number().min(0).default(0),
    material_reorder_level: z.number().min(0).optional().nullable(),
});

// 4. Account Schema
export const accountSchema = z.object({
    first_name: z.string().min(1, "First name is required").trim(),
    last_name: z.string().min(1, "Last name is required").trim(),
    email: z.string().email("Invalid email address").trim().toLowerCase(),
    contact: z.string().optional().nullable(),
    role: z.enum(['customer', 'staff', 'admin']),
    password: z.string()
        .min(8, "Password must be at least 8 characters")
        .regex(/[A-Z]/, "Must contain an uppercase letter")
        .regex(/[a-z]/, "Must contain a lowercase letter")
        .regex(/\d/, "Must contain a number")
        .regex(/[!@#$%^&*(),.?":{}|<>]/, "Must contain a special character")
        .optional()
        .or(z.literal('')), // Optional for editing, required for new
}).refine((data) => {
    // Custom refinement can be added here if needed
    return true;
});

// 5. Auth / Login Schema
export const authLoginSchema = z.object({
    email: z.string().min(1, "Email or Username is required").trim(),
    password: z.string().min(1, "Password is required"),
});

// 6. Auth / Signup Schema
export const authSignupSchema = z.object({
    firstName: z.string().min(1, "First name is required").trim(),
    lastName: z.string().min(1, "Last name is required").trim(),
    username: z.string().min(3, "Username must be at least 3 characters").trim(),
    phone: z.string().min(10, "Invalid phone number").trim(),
    email: z.string().email("Invalid email address").trim().toLowerCase(),
    password: z.string()
        .min(8, "Password must be at least 8 characters")
        .regex(/[A-Z]/, "Must contain an uppercase letter")
        .regex(/[a-z]/, "Must contain a lowercase letter")
        .regex(/\d/, "Must contain a number")
        .regex(/[!@#$%^&*(),.?":{}|<>]/, "Must contain a special character"),
    confirmPassword: z.string()
}).refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
});
