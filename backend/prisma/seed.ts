import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Database seeded.');
}

main().catch(console.error).finally(() => prisma.$disconnect());
